enum SubscriptionPlan: String, CaseIterable, Codable, Identifiable, Hashable {
    case free
    case pro
    case black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        case .black: "Black"
        }
    }
}
