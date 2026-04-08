import StoreKit
import Observation

// MARK: - StoreManager

@MainActor
@Observable
final class StoreManager {

    static let shared = StoreManager()

    // MARK: - Product IDs

    static let proMonthlyID = "com.matcha.ios.pro.monthly"
    static let blackMonthlyID = "com.matcha.ios.black.monthly"

    private static let allProductIDs: Set<String> = [
        proMonthlyID,
        blackMonthlyID,
    ]

    // MARK: - Published State

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var currentPlan: SubscriptionPlan = .free
    var isLoading = false
    var errorMessage: String?

    // MARK: - Welcome Boost (7-day Pro trial after verification)

    private static let boostKey = "matcha_welcome_boost_expires_at"

    var welcomeBoostExpiresAt: Date? {
        get {
            guard let interval = UserDefaults.standard.object(forKey: Self.boostKey) as? Double else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.boostKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.boostKey)
            }
        }
    }

    /// Days remaining on the Welcome Boost (0 if expired or not active).
    var welcomeBoostDaysLeft: Int {
        guard let expiresAt = welcomeBoostExpiresAt else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: .now, to: expiresAt).day ?? 0
        return max(remaining, 0)
    }

    /// True when the Welcome Boost is active and not expired.
    var isWelcomeBoostActive: Bool {
        guard let expiresAt = welcomeBoostExpiresAt else { return false }
        return expiresAt > .now
    }

    // MARK: - Private

    private nonisolated(unsafe) var transactionListener: Task<Void, Never>?

    private init() {}

    // MARK: - Load Products

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            // Sort so Pro comes before Black
            products = storeProducts.sorted { lhs, _ in
                lhs.id == Self.proMonthlyID
            }
        } catch {
            errorMessage = "Failed to load products. Please try again."
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            errorMessage = "Purchase is pending approval."
            return nil

        @unknown default:
            errorMessage = "Unknown purchase result."
            return nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Update Subscription Status

    func updateSubscriptionStatus() async {
        var activePurchases: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                activePurchases.insert(transaction.productID)
            }
        }

        purchasedProductIDs = activePurchases
        currentPlan = resolvedPlan
    }

    // MARK: - Transaction Listener

    /// Call once at app launch. Returns the listener task so the caller can hold it.
    @discardableResult
    func listenForTransactions() -> Task<Void, Never> {
        // Cancel any existing listener before creating a new one
        transactionListener?.cancel()

        let task = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
        transactionListener = task
        return task
    }

    // MARK: - Welcome Boost

    /// Grants 7-day Pro trial. Call once after the user becomes verified.
    func grantWelcomeBoost() {
        guard welcomeBoostExpiresAt == nil else { return } // Only once
        welcomeBoostExpiresAt = Calendar.current.date(byAdding: .day, value: 7, to: .now)
        // Re-evaluate plan so the UI picks up Pro immediately
        currentPlan = resolvedPlan
    }

    // MARK: - Helpers

    /// The effective plan considering StoreKit subscriptions and Welcome Boost.
    private var resolvedPlan: SubscriptionPlan {
        if purchasedProductIDs.contains(Self.blackMonthlyID) {
            return .black
        } else if purchasedProductIDs.contains(Self.proMonthlyID) {
            return .pro
        } else if isWelcomeBoostActive {
            return .pro
        }
        return .free
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    /// Returns the StoreKit `Product` for a given plan, if loaded.
    func product(for plan: SubscriptionPlan) -> Product? {
        switch plan {
        case .pro:   products.first { $0.id == Self.proMonthlyID }
        case .black: products.first { $0.id == Self.blackMonthlyID }
        case .free:  nil
        }
    }
}
