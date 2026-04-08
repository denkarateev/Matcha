enum AppTab: Int, CaseIterable, Identifiable {
    case offers
    case activity
    case match
    case chats
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .offers:   "Offers"
        case .activity: "Activity"
        case .match:    "Match"
        case .chats:    "Chats"
        case .profile:  "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .offers:   "tag.fill"
        case .activity: "bell.fill"
        case .match:    "leaf.fill"
        case .chats:    "bubble.fill"
        case .profile:  "person.fill"
        }
    }
}
