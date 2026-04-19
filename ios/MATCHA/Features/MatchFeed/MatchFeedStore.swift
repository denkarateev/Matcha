import Foundation
import Observation

@MainActor
@Observable
final class MatchFeedStore {

    // MARK: - State

    var profiles: [UserProfile] = []
    var filterState: FeedFilterState = FeedFilterState()
    var currentIndex: Int = 0
    var isLoading: Bool = false
    var error: NetworkError?
    var matchCelebration: UserProfile?  // non-nil when a mutual match just happened

    /// Count of profiles who liked current user (from API). Shadow pending likes use ShadowAccountManager.
    var pendingLikes: Int = 0
    var likedByProfiles: [UserProfile] = []
    var showActivationPrompt = false
    var hasLoaded = false
    var toastMessage: String?

    // Shadow Account UI state
    var showShadowActivationSheet = false
    var showShadowBlockedMessage = false

    /// Non-nil while a programmatic swipe animation is in flight.
    /// The view observes this to trigger card-fly-off animation, then calls clearProgrammaticSwipe().
    var programmaticSwipe: SwipeDirection? = nil

    // MARK: - Dependencies

    private let repository: any MatchaRepository
    private var lastSkippedProfileID: UUID?
    /// Snapshot for undo: (profile, original index в массиве profiles до удаления).
    /// Позволяет восстановить скипнутый профиль при Undo tap.
    private var lastSkippedSnapshot: (profile: UserProfile, index: Int)?
    private var toastDismissTask: Task<Void, Never>?

    init(repository: any MatchaRepository) {
        self.repository = repository
    }

    // MARK: - Computed

    func apiFilterParams() -> FeedFilterParams {
        FeedFilterParams(
            niche: filterState.selectedNiches.first?.lowercased(),
            district: filterState.districts.first,
            minFollowers: filterState.minimumFollowers > 0 ? Int(filterState.minimumFollowers) : nil,
            collabType: filterState.collaborationType?.rawValue
        )
    }

    func applyFilterChange() async {
        hasLoaded = false
        await loadFeed()
    }

    var filteredProfiles: [UserProfile] {
        var result = profiles

        switch filterState.roleFilter {
        case .all: break
        case .influencers: result = result.filter { $0.role == .blogger }
        case .businesses: result = result.filter { $0.role == .business }
        }

        if !filterState.selectedNiches.isEmpty {
            let selected = Set(filterState.selectedNiches.map { $0.lowercased() })
            result = result.filter { profile in
                let profileNiches = Set(profile.niches.map { $0.lowercased() })
                return !selected.isDisjoint(with: profileNiches)
            }
        }

        if !filterState.districts.isEmpty {
            let selectedDistricts = Set(filterState.districts.map { $0.lowercased() })
            result = result.filter { profile in
                guard let district = profile.district else { return false }
                return selectedDistricts.contains(district.lowercased())
            }
        }

        if filterState.minimumFollowers > 0 {
            result = result.filter { profile in
                Double(profile.followersCount ?? 0) >= filterState.minimumFollowers
            }
        }

        if let collab = filterState.collaborationType {
            result = result.filter { $0.collaborationType == collab || $0.collaborationType == .both }
        }

        return result
    }

    var currentProfile: UserProfile? {
        let list = filteredProfiles
        guard !list.isEmpty else { return nil }
        // Keep currentIndex within bounds of filtered list
        let idx = min(currentIndex, list.count - 1)
        return list[idx]
    }

    private var currentUserID: String? {
        NetworkService.shared.currentUserID
    }

    // MARK: - Load

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        syncShadowState()
        // Flush any offline-queued swipes first
        await OfflineSwipeQueue.flush(repository: repository)
        await loadFeed()
    }

    func loadFeed() async {
        isLoading = true
        error = nil
        hasLoaded = true

        let previousProfileID = currentProfile?.id
        var feedError: NetworkError?
        var summaryError: NetworkError?

        do {
            let fetchedProfiles = try await repository.fetchMatchFeed(filters: apiFilterParams())
            profiles = ProcessedDiscoveryProfileStore.filter(
                fetchedProfiles,
                currentUserID: currentUserID
            )
        } catch let networkError as NetworkError {
            feedError = networkError
        } catch {
            feedError = .networkError(error)
        }

        do {
            let activity = try await repository.fetchActivitySummary()
            likedByProfiles = ProcessedDiscoveryProfileStore.filter(
                activity.likes,
                currentUserID: currentUserID
            )
            pendingLikes = likedByProfiles.count
        } catch let networkError as NetworkError {
            summaryError = networkError
        } catch {
            summaryError = .networkError(error)
        }

        if let previousProfileID,
           let restoredIndex = profiles.firstIndex(where: { $0.id == previousProfileID }) {
            currentIndex = restoredIndex
        } else if profiles.isEmpty {
            currentIndex = 0
        } else {
            currentIndex = min(currentIndex, profiles.count - 1)
        }

        error = profiles.isEmpty ? (feedError ?? summaryError) : nil
        isLoading = false
        syncShadowState()
    }

    // MARK: - Swipe Actions

    func swipe(_ direction: SwipeDirection, profile: UserProfile) async {
        let shadow = ShadowAccountManager.shared

        // Shadow account: block swipe if at max pending likes
        if !shadow.isVerified && (direction == .right || direction == .super) && shadow.isBlocked {
            showShadowBlockedMessage = true
            return
        }

        error = nil
        ProcessedDiscoveryProfileStore.add(profile.id, currentUserID: currentUserID)
        lastSkippedProfileID = direction == .left ? profile.id : nil

        // Remove the swiped profile from feed — user can't scroll back to it.
        // For skip: save snapshot чтобы UndoSkip мог восстановить на исходный индекс.
        if let idx = profiles.firstIndex(where: { $0.id == profile.id }) {
            if direction == .left {
                lastSkippedSnapshot = (profile: profile, index: idx)
            } else {
                lastSkippedSnapshot = nil
            }
            profiles.remove(at: idx)
            // currentIndex теперь указывает на следующий профиль (тот, что был after
            // removed). Держим в пределах списка.
            if currentIndex >= profiles.count {
                currentIndex = max(0, profiles.count - 1)
            }
        } else {
            // Fallback: old behaviour (should never happen, но на всякий)
            moveForward()
        }

        let targetId = profile.serverUserId.isEmpty ? profile.id.uuidString : profile.serverUserId

        // Shadow account: queue likes instead of calling API
        if !shadow.isVerified && (direction == .right || direction == .super) {
            shadow.queueLike(targetId: targetId, direction: direction.rawValue)
            pendingLikes += 1
            showActivationPrompt = pendingLikes >= 3

            toastMessage = "Like saved! Will be delivered after verification"
            toastDismissTask?.cancel()
            toastDismissTask = Task {
                try? await Task.sleep(for: .seconds(3))
                toastMessage = nil
            }

            // Show activation sheet after 3rd shadow right/super swipe
            if shadow.shadowSwipeCount == 3 {
                showShadowActivationSheet = true
            }
            return
        }

        // Verified user: normal flow
        if direction == .right || direction == .super {
            pendingLikes += 1
            showActivationPrompt = pendingLikes >= 3
        }

        // Fire the API call -- queue offline if network fails
        do {
            let outcome = try await repository.swipe(
                targetId: targetId,
                direction: direction
            )
            likedByProfiles.removeAll { $0.id == profile.id }
            if outcome.isMatch {
                matchCelebration = profile
            }
        } catch {
            // Save to offline queue
            OfflineSwipeQueue.enqueue(targetId: targetId, direction: direction.rawValue)
            let label = direction == .left ? "Skip" : "Like"
            toastMessage = "\(label) saved, will sync when online"
            toastDismissTask?.cancel()
            toastDismissTask = Task {
                try? await Task.sleep(for: .seconds(3))
                toastMessage = nil
            }
        }
    }

    /// Triggers a programmatic swipe animation in the view, which will call the appropriate action.
    /// The view animates the card off-screen, then calls skip()/interested()/superSwipe() directly.
    func animateSwipe(_ direction: SwipeDirection) {
        programmaticSwipe = direction
    }

    /// Called by the view after the programmatic swipe animation completes.
    func clearProgrammaticSwipe() {
        programmaticSwipe = nil
    }

    func syncShadowState() {
        let shadow = ShadowAccountManager.shared
        guard shadow.isVerified else { return }

        showShadowActivationSheet = false
        showShadowBlockedMessage = false
        showActivationPrompt = false

        if toastMessage == "Like saved! Will be delivered after verification" {
            toastMessage = nil
        }
    }

    /// Called from view after dismissing the match celebration overlay.
    func dismissMatch() {
        matchCelebration = nil
    }

    func resolveChatPreview(for profile: UserProfile) async throws -> ChatPreview {
        // Retry a few times — backend may take a moment to create the chat after match
        for attempt in 0..<4 {
            let home = try await repository.fetchChatHome()
            // Try to match by partner.id (UUID) first
            if let chat = home.conversations.first(where: { $0.partner.id == profile.id }) {
                return chat
            }
            // Fallback — match by serverUserId
            if let chat = home.conversations.first(where: { $0.partner.serverUserId == profile.serverUserId && !profile.serverUserId.isEmpty }) {
                return chat
            }
            // Also check new matches (unopened chats)
            if let newMatch = home.newMatches.first(where: { $0.profile.id == profile.id || $0.profile.serverUserId == profile.serverUserId }) {
                // Synthesise a ChatPreview from the new match
                return ChatPreview(
                    id: UUID(uuidString: newMatch.matchId) ?? UUID(),
                    partner: newMatch.profile,
                    lastMessage: "Say hi!",
                    timestampText: "New match",
                    unreadCount: 0,
                    translationNote: nil,
                    isMuted: false,
                    activeDealStatus: nil,
                    dealSummary: nil
                )
            }

            // Wait briefly, then retry (chat creation is async on backend)
            if attempt < 3 {
                try await Task.sleep(nanoseconds: 400_000_000)
            }
        }

        throw NetworkError.domainError(
            code: "chat_unavailable",
            message: "Chat is taking longer than usual to open. Try again or pull to refresh in Chats."
        )
    }

    // MARK: - Legacy helpers (used by MatchFeedView buttons)

    func skip() {
        guard let profile = currentProfile else { return }
        Task { await swipe(.left, profile: profile) }
    }

    func interested() {
        guard let profile = currentProfile else { return }
        Task { await swipe(.right, profile: profile) }
    }

    func superSwipe() {
        guard let profile = currentProfile else { return }
        Task { await swipe(.super, profile: profile) }
    }

    // MARK: - Undo

    /// Reverses the last left swipe — восстанавливает профиль в массиве на
    /// исходный индекс, убирает из processed store и scrollPosition
    /// автоматически синхронизируется (onChange of currentIndex).
    func undoSkip() {
        guard let snapshot = lastSkippedSnapshot else { return }
        let insertIndex = min(snapshot.index, profiles.count)
        profiles.insert(snapshot.profile, at: insertIndex)
        currentIndex = insertIndex  // наводим курсор на восстановленный профиль
        ProcessedDiscoveryProfileStore.remove(snapshot.profile.id, currentUserID: currentUserID)
        lastSkippedSnapshot = nil
        lastSkippedProfileID = nil
    }

    // MARK: - Private

    private func moveForward() {
        currentIndex += 1
    }

    private func dummyProfile() -> UserProfile {
        UserProfile(
            id: .init(),
            name: "",
            role: .blogger,
            heroSymbol: "",
            countryCode: "",
            audience: "",
            category: nil,
            district: nil,
            niches: [],
            languages: [],
            bio: "",
            collaborationType: .both,
            rating: nil,
            verifiedVisits: 0,
            badges: [],
            subscriptionPlan: .free,
            hasActiveOffer: false,
            isVerified: false
        )
    }
}

enum ProcessedDiscoveryProfileStore {
    private static let keyPrefix = "matcha_processed_discovery_profile_ids"

    static func filter(_ profiles: [UserProfile], currentUserID: String?) -> [UserProfile] {
        let hiddenIDs = ids(currentUserID: currentUserID)
        guard !hiddenIDs.isEmpty else { return profiles }
        return profiles.filter { !hiddenIDs.contains($0.id.uuidString) }
    }

    static func add(_ profileID: UUID, currentUserID: String?) {
        update(currentUserID: currentUserID) { ids in
            ids.insert(profileID.uuidString)
        }
    }

    static func remove(_ profileID: UUID, currentUserID: String?) {
        update(currentUserID: currentUserID) { ids in
            ids.remove(profileID.uuidString)
        }
    }

    private static func ids(currentUserID: String?) -> Set<String> {
        guard let key = storageKey(for: currentUserID) else { return [] }
        return Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    private static func update(
        currentUserID: String?,
        mutate: (inout Set<String>) -> Void
    ) {
        guard let key = storageKey(for: currentUserID) else { return }
        var storedIDs = ids(currentUserID: currentUserID)
        mutate(&storedIDs)
        UserDefaults.standard.set(Array(storedIDs).sorted(), forKey: key)
    }

    private static func storageKey(for currentUserID: String?) -> String? {
        guard let currentUserID, !currentUserID.isEmpty else { return nil }
        return "\(keyPrefix).\(currentUserID)"
    }
}

// MARK: - Offline Swipe Queue

enum OfflineSwipeQueue {
    private static let key = "matcha_offline_swipe_queue"

    struct PendingSwipe: Codable {
        let targetId: String
        let direction: String
        let timestamp: Date
    }

    static func enqueue(targetId: String, direction: String) {
        var queue = load()
        queue.append(PendingSwipe(targetId: targetId, direction: direction, timestamp: Date()))
        save(queue)
    }

    @MainActor
    static func flush(repository: any MatchaRepository) async {
        let queue = load()
        guard !queue.isEmpty else { return }

        var remaining: [PendingSwipe] = []
        for swipe in queue {
            do {
                let dir = SwipeDirection(rawValue: swipe.direction) ?? .right
                _ = try await repository.swipe(targetId: swipe.targetId, direction: dir)
            } catch {
                remaining.append(swipe)
            }
        }
        save(remaining)
    }

    static var count: Int { load().count }

    private static func load() -> [PendingSwipe] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([PendingSwipe].self, from: data)) ?? []
    }

    private static func save(_ queue: [PendingSwipe]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
