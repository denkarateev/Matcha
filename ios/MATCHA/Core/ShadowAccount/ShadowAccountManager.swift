import Foundation
import Observation

// MARK: - ShadowAccountManager

/// Manages the "shadow account" flow: unverified users can browse and swipe,
/// but their right/super likes are queued locally (max 20) instead of hitting the API.
/// Once the user verifies, queued likes are delivered via drip (3-5 per hour).
@MainActor
@Observable
final class ShadowAccountManager {

    static let shared = ShadowAccountManager()

    // MARK: - Public State

    var pendingLikesCount: Int { pendingLikes.count }
    var isVerified: Bool = false
    let maxPendingLikes: Int = 20

    /// Number of right/super swipes made while in shadow mode (persisted).
    /// Used to trigger the activation prompt after the 3rd swipe.
    private(set) var shadowSwipeCount: Int = 0

    // MARK: - Computed

    var canSwipe: Bool {
        isVerified || pendingLikesCount < maxPendingLikes
    }

    var isBlocked: Bool {
        !isVerified && pendingLikesCount >= maxPendingLikes
    }

    // MARK: - Private

    private var pendingLikes: [PendingLike] = []
    private var dripTask: Task<Void, Never>?

    private static let pendingLikesKey = "matcha_shadow_pending_likes"
    private static let shadowSwipeCountKey = "matcha_shadow_swipe_count"

    // MARK: - Init

    private init() {
        load()
    }

    // MARK: - Queue a Like

    func queueLike(targetId: String, direction: String) {
        guard pendingLikesCount < maxPendingLikes else { return }

        let like = PendingLike(
            targetId: targetId,
            direction: direction,
            timestamp: Date()
        )
        pendingLikes.append(like)
        shadowSwipeCount += 1
        save()
    }

    // MARK: - Drip Delivery

    /// Delivers all pending likes at a rate of 3-5 per hour.
    /// Called once after the user becomes verified.
    func startDripDelivery(repository: any MatchaRepository) {
        // Cancel any existing drip
        dripTask?.cancel()

        guard !pendingLikes.isEmpty else { return }

        dripTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard !self.pendingLikes.isEmpty else { break }

                // Deliver 1 like
                let like = self.pendingLikes[0]
                let direction = SwipeDirection(rawValue: like.direction) ?? .right

                do {
                    _ = try await repository.swipe(
                        targetId: like.targetId,
                        direction: direction
                    )
                    self.pendingLikes.removeFirst()
                    self.save()
                } catch {
                    // Network failure -- retry on next tick
                }

                guard !Task.isCancelled else { break }

                // Drip interval: 3-5 likes/hour = 1 like every 12-20 minutes
                let delaySeconds = Int.random(in: 720...1200)
                try? await Task.sleep(for: .seconds(delaySeconds))
            }
        }
    }

    /// Delivers all pending likes immediately (batch, no drip).
    /// Fallback if drip is not desired.
    func deliverPendingLikes(repository: any MatchaRepository) async {
        var remaining: [PendingLike] = []

        for like in pendingLikes {
            let direction = SwipeDirection(rawValue: like.direction) ?? .right
            do {
                _ = try await repository.swipe(
                    targetId: like.targetId,
                    direction: direction
                )
            } catch {
                remaining.append(like)
            }
        }

        pendingLikes = remaining
        save()
    }

    /// Resets shadow state after verification (keeps pending likes for delivery).
    func markVerified() {
        isVerified = true
        shadowSwipeCount = 0
        UserDefaults.standard.set(0, forKey: Self.shadowSwipeCountKey)
    }

    /// Full reset (sign-out).
    func reset() {
        dripTask?.cancel()
        dripTask = nil
        pendingLikes = []
        shadowSwipeCount = 0
        isVerified = false
        UserDefaults.standard.removeObject(forKey: Self.pendingLikesKey)
        UserDefaults.standard.removeObject(forKey: Self.shadowSwipeCountKey)
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(pendingLikes) {
            UserDefaults.standard.set(data, forKey: Self.pendingLikesKey)
        }
        UserDefaults.standard.set(shadowSwipeCount, forKey: Self.shadowSwipeCountKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Self.pendingLikesKey),
           let decoded = try? JSONDecoder().decode([PendingLike].self, from: data) {
            pendingLikes = decoded
        }
        shadowSwipeCount = UserDefaults.standard.integer(forKey: Self.shadowSwipeCountKey)
    }
}

// MARK: - PendingLike

extension ShadowAccountManager {
    struct PendingLike: Codable {
        let targetId: String
        let direction: String // "right" or "super"
        let timestamp: Date
    }
}
