enum Role: String, CaseIterable, Codable, Identifiable, Hashable {
    case blogger
    case business

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blogger: "Influencer"
        case .business: "Business"
        }
    }

    var subtitle: String {
        switch self {
        case .blogger: "Influencers, nano to macro."
        case .business: "Restaurants, villas, spas, clubs and brands."
        }
    }
}
