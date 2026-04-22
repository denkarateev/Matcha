import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class AppState {
    // MARK: - Navigation

    var selectedTab: AppTab = .match

    // MARK: - Auth State

    /// Stored property — triggers SwiftUI updates when changed.
    var isAuthenticated: Bool = NetworkService.shared.isAuthenticated

    /// Onboarding complete = authenticated OR explicitly completed.
    var onboardingComplete: Bool = false

    /// Observable flag — triggers SwiftUI updates. Also persisted in UserDefaults.
    var _onboardingCompleteFlag: Bool = UserDefaults.standard.bool(forKey: "matcha_onboarding_complete") {
        didSet { UserDefaults.standard.set(_onboardingCompleteFlag, forKey: "matcha_onboarding_complete") }
    }

    // MARK: - Current User

    /// The authenticated user's profile fetched from the API.
    /// Falls back to a local placeholder while loading.
    var currentUser: UserProfile = MockSeedData.makeCurrentUser(role: .blogger, name: "You")

    /// The full auth user record (role, plan tier, verification level).
    var authUser: AuthUser?

    // MARK: - Badge Counts (will be replaced by real counts from activity/chat APIs)

    var dealsBadgeCount = 0
    var chatBadgeCount = 0
    var offersBadgeCount = 0

    // MARK: - Shadow Account

    /// Message shown when shadow likes are activated after verification.
    var shadowActivationMessage: String?

    // MARK: - Loading / Error State

    var isLoadingUser = false
    var userLoadError: NetworkError?

    /// True while the app is performing initial auth bootstrap.
    /// UI should show a loading/splash screen until this becomes false.
    var isBootstrapping = true

    private var authInvalidationObserver: NSObjectProtocol?

    init() {
        authInvalidationObserver = NotificationCenter.default.addObserver(
            forName: NetworkService.sessionInvalidatedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleSessionInvalidation()
            }
        }
    }

    // MARK: - Auth Bootstrap

    /// Called on app launch. Restores an existing authenticated session from backend.
    func bootstrapIfNeeded(useLiveServices: Bool, repository: (any MatchaRepository)? = nil) async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        // Start listening for StoreKit transaction updates
        StoreManager.shared.listenForTransactions()
        await StoreManager.shared.updateSubscriptionStatus()

        guard useLiveServices else {
            // UI Test mode: auto-complete onboarding with mock user
            if ProcessInfo.processInfo.arguments.contains("-UITest") {
                completeOnboarding(role: .blogger, name: "Test User", category: nil)
                return
            }
            guard isAuthenticated else { return }
            await loadCurrentUser(repository: repository)
            syncSubscriptionPlan()
            return
        }

        // Test injection: allow UI tests to inject credentials via env
        if let testToken = ProcessInfo.processInfo.environment["MATCHA_TEST_TOKEN"],
           let testUserID = ProcessInfo.processInfo.environment["MATCHA_TEST_USER_ID"],
           !testToken.isEmpty {
            let testRole = Role(rawValue: ProcessInfo.processInfo.environment["MATCHA_TEST_ROLE"] ?? "blogger") ?? .blogger
            NetworkService.shared.applySession(token: testToken, userID: testUserID, role: testRole)
            print("[MATCHA] Test credentials injected for user \(testUserID)")
        }

        let hasToken = NetworkService.shared.isAuthenticated
        print("[MATCHA] Bootstrap live: hasToken=\(hasToken)")
        guard hasToken else {
            handleSessionInvalidation()
            print("[MATCHA] No token — showing onboarding")
            return
        }
        isAuthenticated = true
        // BUG-08 fixed: читаем persisted onboarding flag при bootstrap.
        // Если юзер был аутентифицирован + раньше завершил онбординг → skip.
        // Если по какой-то причине flag=false (migration) → форсим true
        // для бэкенд-аутентифицированных чтобы не зацикливать onboarding.
        onboardingComplete = _onboardingCompleteFlag || true
        _onboardingCompleteFlag = true
        await loadCurrentUser(repository: repository)
        syncSubscriptionPlan()
        if case .unauthorized? = userLoadError {
            print("[MATCHA] Token expired — forcing re-login")
            handleSessionInvalidation()
        } else {
            print("[MATCHA] Session valid — showing tabs")
        }
    }

    // MARK: - Load Current User

    func loadCurrentUser(repository: (any MatchaRepository)? = nil) async {
        isLoadingUser = true
        userLoadError = nil

        let previousLevel = currentUser.verificationLevel

        do {
            let fetched = try await AuthService.shared.fetchCurrentUser()
            authUser = fetched

            // Fetch full profile
            let profile: ProfileRead = try await NetworkService.shared.request(
                .GET,
                path: "/profiles/me"
            )
            currentUser = UserProfile.from(profile: profile, user: fetched)

            // Detect shadow -> verified transition and trigger drip delivery
            let shadow = ShadowAccountManager.shared
            if previousLevel == .shadow
                && fetched.verificationLevel.isVerified
                && !shadow.isVerified
                && shadow.pendingLikesCount > 0 {
                shadow.markVerified()
                if let repository {
                    shadow.startDripDelivery(repository: repository)
                }
                let count = shadow.pendingLikesCount
                shadowActivationMessage = "You're in the blend! Your \(count) likes are now active!"

                // Grant 7-day Pro welcome boost on first verification
                StoreManager.shared.grantWelcomeBoost()
            } else if fetched.verificationLevel.isVerified {
                // Keep shadow manager in sync
                shadow.markVerified()
            }
        } catch let error as NetworkError {
            if case .unauthorized = error {
                handleSessionInvalidation()
            }
            userLoadError = error
        } catch {
            userLoadError = .networkError(error)
        }
        isLoadingUser = false
    }

    // MARK: - Onboarding Completion (called after register/login)

    /// Called after a successful auth API call. Stores the user and transitions to main tab.
    func completeAuthOnboarding(authResponse: AuthResponse) {
        authUser = authResponse.user

        // Build a lightweight placeholder user profile from auth data
        currentUser = UserProfile(
            id: UUID(uuidString: authResponse.user.id) ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            name: authResponse.user.fullName,
            role: authResponse.user.role,
            heroSymbol: authResponse.user.role == .business
                ? "storefront.circle.fill"
                : "person.crop.circle.badge.checkmark",
            countryCode: "ID",
            audience: authResponse.user.role == .business ? "Business" : "Shadow profile",
            category: nil,
            district: nil,
            niches: [],
            languages: [],
            bio: "",
            collaborationType: .both,
            rating: nil,
            verifiedVisits: 0,
            badges: [.newcomer],
            subscriptionPlan: authResponse.user.planTier,
            hasActiveOffer: false,
            isVerified: authResponse.user.verificationLevel.isVerified,
            verificationLevel: authResponse.user.verificationLevel,
            followersCount: nil
        )

        isAuthenticated = true
        onboardingComplete = true
        _onboardingCompleteFlag = true
        selectedTab = .match
    }

    /// Legacy path for mock/preview only — kept for previews and simulator testing.
    func completeOnboarding(role: Role, name: String, category: BusinessCategory?) {
        currentUser = MockSeedData.makeCurrentUser(role: role, name: name, category: category)
        isAuthenticated = true
        onboardingComplete = true
        _onboardingCompleteFlag = true
        selectedTab = .match
    }

    // MARK: - Sync StoreKit Subscription

    /// Updates currentUser.subscriptionPlan from the StoreKit-resolved plan.
    /// BUG-07 fixed: subscriptionPlan теперь `var` → прямое присвоение вместо
    /// пересоздания всего UserProfile с копированием 20+ полей.
    func syncSubscriptionPlan() {
        let storePlan = StoreManager.shared.currentPlan
        guard currentUser.subscriptionPlan != storePlan else { return }
        currentUser.subscriptionPlan = storePlan
    }

    // MARK: - Sign Out

    func signOut() {
        AuthService.shared.signOut()
        handleSessionInvalidation()
    }

    private func handleSessionInvalidation() {
        authUser = nil
        currentUser = MockSeedData.makeCurrentUser(role: .blogger, name: "You")
        isAuthenticated = false
        onboardingComplete = false
        _onboardingCompleteFlag = false
        dealsBadgeCount = 0
        chatBadgeCount = 0
        offersBadgeCount = 0
        selectedTab = .match
        ShadowAccountManager.shared.reset()
    }
}
