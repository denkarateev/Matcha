enum ProfileBadge: String, CaseIterable, Codable, Identifiable, Hashable {
    case verified
    case blueCheck
    case firstDeal
    case ideaCreator
    case newcomer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .verified: "Verified"
        case .blueCheck: "Blue Check"
        case .firstDeal: "First Deal"
        case .ideaCreator: "Idea Creator"
        case .newcomer: "New"
        }
    }

    var symbol: String {
        switch self {
        case .verified: "checkmark.seal.fill"
        case .blueCheck: "diamond.fill"
        case .firstDeal: "star.fill"
        case .ideaCreator: "lightbulb.fill"
        case .newcomer: "sparkles"
        }
    }
}
