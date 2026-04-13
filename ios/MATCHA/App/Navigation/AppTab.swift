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

    var title: String {
        switch self {
        case .offers:  "Offers"
        case .likes:   "Activity"
        case .match:   "Match"
        case .chats:   "Chats"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .offers:  "tag.fill"
        case .likes:   "heart.fill"
        case .match:   "leaf.fill"
        case .chats:   "bubble.fill"
        case .profile: "person.fill"
        }
    }
}
