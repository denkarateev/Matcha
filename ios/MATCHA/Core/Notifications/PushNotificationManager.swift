import UserNotifications
import UIKit
import Observation

@MainActor
@Observable
final class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    var isAuthorized = false
    var deviceToken: String?
    var hasRequestedPermission = false

    // MARK: - Request Permission (spec 4.5: after first match)

    func requestPermissionIfNeeded() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true
        UserDefaults.standard.set(true, forKey: "matcha_push_requested")

        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                isAuthorized = granted
                if granted {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            } catch {
                isAuthorized = false
            }
        }
    }

    // MARK: - Check Current Status

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        hasRequestedPermission = UserDefaults.standard.bool(forKey: "matcha_push_requested")
    }

    // MARK: - Handle Device Token

    func didRegisterForRemoteNotifications(token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        // Send to backend
        Task {
            try? await NetworkService.shared.request(
                .POST,
                path: "/auth/device-token",
                body: DeviceTokenRequest(token: tokenString, platform: "ios")
            ) as EmptyAPIResponse
        }
    }

    // MARK: - Schedule Local Notifications

    /// Match notification (spec 13.2)
    func notifyMatch(partnerName: String) {
        scheduleLocal(
            title: "Fresh Match! ☕",
            body: "\(partnerName) wants to connect",
            categoryID: "match"
        )
    }

    /// Deal confirmed (spec 13.3)
    func notifyDealConfirmed(partnerName: String, date: String?) {
        let body = date != nil
            ? "Deal confirmed! See you on \(date!)!"
            : "Your matcha is brewing ☕"
        scheduleLocal(title: "Deal Confirmed", body: body, categoryID: "deal")
    }

    /// Check-in complete (spec 13.3)
    func notifyCheckInComplete(partnerName: String) {
        scheduleLocal(
            title: "Perfect blend!",
            body: "Rate your experience with \(partnerName) ☕",
            categoryID: "deal"
        )
    }

    /// Content proof received (spec 13.3)
    func notifyContentProof(partnerName: String) {
        scheduleLocal(
            title: "Content Published!",
            body: "\(partnerName) published content! Check it out",
            categoryID: "deal"
        )
    }

    /// Return push sequence (spec 4.6)
    func scheduleReturnPushes() {
        // 6h
        scheduleLocal(
            title: "New opportunities!",
            body: "4 businesses are looking for bloggers in your niche",
            categoryID: "return",
            delay: 6 * 3600
        )
        // 24h
        scheduleLocal(
            title: "Don't miss out!",
            body: "12 new profiles appeared! Complete registration to find them",
            categoryID: "return",
            delay: 24 * 3600
        )
        // 72h (last)
        scheduleLocal(
            title: "Your matcha is getting cold!",
            body: "You missed 12 potential collabs!",
            categoryID: "return",
            delay: 72 * 3600
        )
    }

    /// Inactive push (spec 13.4)
    func scheduleInactivePush() {
        // 3 days
        scheduleLocal(
            title: "Your matcha is getting cold!",
            body: "4 new businesses appeared",
            categoryID: "inactive",
            delay: 3 * 24 * 3600
        )
    }

    // MARK: - Private

    private func scheduleLocal(
        title: String,
        body: String,
        categoryID: String,
        delay: TimeInterval = 0.5
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryID

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 0.5), repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(categoryID)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Request Types

private struct DeviceTokenRequest: Encodable {
    let token: String
    let platform: String
}
