import SwiftUI

enum ProfileBadge: String, CaseIterable, Codable, Identifiable, Hashable {
    case verified
    case blueCheck
    case firstDeal
    case ideaCreator
    case newcomer
    // Gamified milestones
    case freshBrew       // 1st completed collab
    case regular         // 5 completed collabs
    case barista         // 10 completed collabs
    case topCreator      // Featured this month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .verified: "Verified"
        case .blueCheck: "Blue Check"
        case .firstDeal: "First Deal"
        case .ideaCreator: "Idea Creator"
        case .newcomer: "New"
        case .freshBrew: "Fresh Brew"
        case .regular: "Regular"
        case .barista: "Barista"
        case .topCreator: "Top Creator"
        }
    }

    var symbol: String {
        switch self {
        case .verified: "checkmark.seal.fill"
        case .blueCheck: "diamond.fill"
        case .firstDeal: "star.fill"
        case .ideaCreator: "lightbulb.fill"
        case .newcomer: "sparkles"
        case .freshBrew: "cup.and.saucer.fill"
        case .regular: "flame.fill"
        case .barista: "trophy.fill"
        case .topCreator: "crown.fill"
        }
    }

    var color: Color {
        switch self {
        case .verified: MatchaTokens.Colors.success
        case .blueCheck: Color(hex: 0x1DA1F2)
        case .firstDeal: MatchaTokens.Colors.warning
        case .ideaCreator: Color.purple
        case .newcomer: MatchaTokens.Colors.accent
        case .freshBrew: MatchaTokens.Colors.accent
        case .regular: Color.orange
        case .barista: MatchaTokens.Colors.warning
        case .topCreator: Color(hex: 0xFFD700)
        }
    }

    var subtitle: String {
        switch self {
        case .freshBrew: "Complete your first collab"
        case .regular: "Complete 5 collabs"
        case .barista: "Complete 10 collabs"
        case .topCreator: "Featured creator this month"
        default: ""
        }
    }
}
