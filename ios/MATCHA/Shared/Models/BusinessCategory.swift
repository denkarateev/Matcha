enum BusinessCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case restaurantCafe
    case hotelVilla
    case spaWellness
    case activitySport
    case clubBar
    case coworkingRetail
    case brandShop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurantCafe: "Restaurant / Cafe"
        case .hotelVilla: "Hotel / Villa"
        case .spaWellness: "Spa / Wellness"
        case .activitySport: "Activity / Sport"
        case .clubBar: "Club / Bar"
        case .coworkingRetail: "Coworking / Retail"
        case .brandShop: "Brand / Shop"
        }
    }
}
