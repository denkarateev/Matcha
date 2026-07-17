/// Mirrors backend DealStatus string enum.
/// Raw values match the backend snake_case strings.
enum DealStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case draft      = "draft"
    case confirmed  = "confirmed"
    case visited    = "visited"
    case reviewed   = "reviewed"
    case cancelled  = "cancelled"
    case noShow     = "no_show"

    var id: String { rawValue }

    /// Non-terminal statuses — the deal still needs action from either side.
    var isActive: Bool {
        switch self {
        case .draft, .confirmed, .visited: true
        case .reviewed, .cancelled, .noShow: false
        }
    }

    var title: String {
        switch self {
        case .draft:      "Draft"
        case .confirmed:  "Confirmed"
        case .visited:    "Visited"
        case .reviewed:   "Reviewed"
        case .cancelled:  "Cancelled"
        case .noShow:     "No-Show"
        }
    }
}
