import Foundation

enum AppTab: Int, CaseIterable, Identifiable {
    case offers
    case likes
    case match
    case chats
    case profile

    /// Legacy aliases so existing code still compiles.
    static let activity: AppTab = .likes
    static let notifications: AppTab = .likes

    var id: Int { rawValue }

    /// Debug-only: lets a screenshot pass open a specific tab (MATCHA_TAB=chats).
    static var debugInitialTab: AppTab? {
        switch ProcessInfo.processInfo.environment["MATCHA_TAB"] {
        case "offers": .offers
        case "likes": .likes
        case "match": .match
        case "chats": .chats
        case "profile": .profile
        default: nil
        }
    }

    var title: String {
        switch self {
        case .offers:  "Discover"
        case .likes:   "Likes"
        case .match:   "Match"
        case .chats:   "Chats"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .offers:  "tag.fill"
        case .likes:   "heart.fill"
        case .match:   "circle.fill"
        case .chats:   "bubble.fill"
        case .profile: "person.fill"
        }
    }
}
