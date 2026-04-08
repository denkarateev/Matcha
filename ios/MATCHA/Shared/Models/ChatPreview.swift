import Foundation

struct ChatPreview: Identifiable, Hashable {
    let id: UUID
    let chatID: String
    let partner: UserProfile
    let lastMessage: String
    let timestampText: String
    let unreadCount: Int
    let translationNote: String?
    let isMuted: Bool
    let activeDealStatus: DealStatus?
    let dealSummary: ChatDealSummary?
    let matchId: String?
    let matchSource: String?
    let firstMessageByUserId: String?
    let createdAt: Date?
    let isAwaitingFirstMessage: Bool
    let matchExpiresAt: Date?

    init(
        id: UUID = UUID(),
        chatID: String? = nil,
        partner: UserProfile,
        lastMessage: String,
        timestampText: String,
        unreadCount: Int,
        translationNote: String? = nil,
        isMuted: Bool = false,
        activeDealStatus: DealStatus? = nil,
        dealSummary: ChatDealSummary? = nil,
        matchId: String? = nil,
        matchSource: String? = nil,
        firstMessageByUserId: String? = nil,
        createdAt: Date? = nil,
        isAwaitingFirstMessage: Bool = false,
        matchExpiresAt: Date? = nil
    ) {
        self.id = id
        self.chatID = chatID ?? id.uuidString
        self.partner = partner
        self.lastMessage = lastMessage
        self.timestampText = timestampText
        self.unreadCount = unreadCount
        self.translationNote = translationNote
        self.isMuted = isMuted
        self.activeDealStatus = dealSummary?.status ?? activeDealStatus
        self.dealSummary = dealSummary
        self.matchId = matchId
        self.matchSource = matchSource
        self.firstMessageByUserId = firstMessageByUserId
        self.createdAt = createdAt
        self.isAwaitingFirstMessage = isAwaitingFirstMessage
        self.matchExpiresAt = matchExpiresAt
    }

    var requiresAction: Bool {
        dealSummary?.cta != nil
    }

    var isSwipeMatch: Bool {
        matchSource == "swipe"
    }
}
