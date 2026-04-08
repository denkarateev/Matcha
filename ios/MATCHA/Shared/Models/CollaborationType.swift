enum CollaborationType: String, CaseIterable, Codable, Identifiable, Hashable {
    case barter
    case paid
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .barter: "Barter"
        case .paid: "Paid"
        case .both: "Both"
        }
    }
}
