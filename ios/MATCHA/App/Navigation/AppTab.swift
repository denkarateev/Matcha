enum AppTab: Int, CaseIterable, Identifiable {
    case offers
    case notifications
    case match
    case chats
    case profile

    /// Legacy alias so existing code referencing `.activity` still compiles.
    static let activity: AppTab = .notifications

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .offers:        "Offers"
        case .notifications: "Notifications"
        case .match:         "Match"
        case .chats:         "Chats"
        case .profile:       "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .offers:        "tag.fill"
        case .notifications: "bell.fill"
        case .match:         "leaf.fill"
        case .chats:         "bubble.fill"
        case .profile:       "person.fill"
        }
    }
}
