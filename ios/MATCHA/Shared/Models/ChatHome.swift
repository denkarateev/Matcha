import Foundation

/// A new match without a chat yet — carries timer info from the backend.
struct NewMatch: Identifiable, Hashable {
    let profile: UserProfile
    let matchId: String
    let expiresAt: Date?
    let createdAt: Date?

    var id: UUID { profile.id }
}

struct ChatHome: Hashable {
    let newMatches: [NewMatch]
    let conversations: [ChatPreview]

    var actionRequiredConversations: [ChatPreview] {
        conversations.filter(\.requiresAction)
    }

    var activeDealCount: Int {
        conversations.filter { $0.activeDealStatus != nil }.count
    }
}
