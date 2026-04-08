enum Role: String, CaseIterable, Codable, Identifiable, Hashable {
    case blogger
    case business

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blogger: "Blogger"
        case .business: "Business"
        }
    }

    var subtitle: String {
        switch self {
        case .blogger: "Creators, influencers, nano to macro."
        case .business: "Restaurants, villas, spas, clubs and brands."
        }
    }
}
