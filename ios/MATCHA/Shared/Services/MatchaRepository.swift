import Foundation

@MainActor
protocol MatchaRepository {
    // MARK: - Feed & Swipe
    func fetchMatchFeed() async throws -> [UserProfile]
    func swipe(targetId: String, direction: SwipeDirection) async throws -> SwipeOutcome
    func matchBack(targetId: String) async throws -> MatchBackResult

    // MARK: - Profiles
    func fetchProfile(userId: String) async throws -> ProfileRead
    func updateProfile(_ update: ProfileUpdateRequest) async throws -> ProfileRead

    // MARK: - Offers
    func fetchOffers() async throws -> [Offer]
    func createOffer(_ request: OfferCreateRequest) async throws -> Offer
    func closeOffer(offerId: String) async throws -> Offer

    // MARK: - Activity
    func fetchActivitySummary() async throws -> ActivitySummary

    // MARK: - Chats
    func fetchChatHome() async throws -> ChatHome
    func fetchChatThread(chatId: String) async throws -> ChatThread
    func sendMessage(chatId: String, request: SendChatMessageRequest) async throws -> ConversationMessage

    // MARK: - Quick Replies
    func fetchQuickReplies(chatId: String) async throws -> [String]

    // MARK: - Chat Actions
    func muteChat(chatId: String) async throws
    func unmuteChat(chatId: String) async throws
    func unmatchChat(chatId: String) async throws

    // MARK: - Deals
    func fetchDeals() async throws -> [DealRead]
    func fetchDeal(dealId: String) async throws -> DealRead
    func createDeal(_ request: DealCreateRequest) async throws -> DealRead
    func acceptDeal(dealId: String) async throws -> DealRead
    func declineDeal(dealId: String) async throws -> DealRead
    func confirmDeal(dealId: String) async throws -> DealRead
    func checkInDeal(dealId: String) async throws -> DealRead
    func submitReview(dealId: String, review: DealReviewRequest) async throws -> DealRead
    func cancelDeal(dealId: String, reason: String) async throws -> DealRead
    func markNoShow(dealId: String) async throws -> DealRead
    func submitContentProof(dealId: String, postUrl: String, screenshotUrl: String?) async throws -> DealRead
    func repeatDeal(dealId: String) async throws -> DealRead

    // MARK: - Account
    func deleteAccount() async throws
}

// MARK: - Deal Review Request

struct DealReviewRequest: Encodable, Sendable {
    let punctuality: Int?
    let offerMatch: Int?
    let communication: Int?
    let comment: String?

    init(punctuality: Int? = nil, offerMatch: Int? = nil, communication: Int? = nil, comment: String? = nil) {
        self.punctuality = punctuality
        self.offerMatch = offerMatch
        self.communication = communication
        self.comment = comment
    }
}

// MARK: - API Response Types for Repository

struct SwipeOutcome: Sendable {
    let isMatch: Bool
    let matchId: String?
}

struct MatchBackResult: Sendable {
    let matchId: String
}

// MARK: - Deal API Types

struct DealRead: Identifiable, Sendable {
    let id: String
    let chatId: String
    let participantIds: [String]
    let initiatorId: String
    let type: CollaborationType
    let offeredText: String
    let requestedText: String
    let placeName: String?
    let guests: String
    let scheduledFor: Date?
    let contentDeadline: Date?
    let status: DealStatus
    let checkedInUserIds: [String]
    let cancellationReason: String?
    let createdAt: Date
    let updatedAt: Date
}

/// Mirrors backend DealRead Pydantic schema for JSON decoding
struct DealReadDTO: Decodable, Sendable {
    let id: String
    let chatId: String
    let participantIds: [String]
    let initiatorId: String
    let type: String
    let offeredText: String
    let requestedText: String
    let placeName: String?
    let guests: String
    let scheduledFor: Date?
    let contentDeadline: Date?
    let status: String
    let checkedInUserIds: [String]
    let cancellationReason: String?
    let repeatedFromDealId: String?
    let reviews: [DealReviewReadDTO]?
    let contentProofs: [ContentProofReadDTO]?
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> DealRead {
        DealRead(
            id: id,
            chatId: chatId,
            participantIds: participantIds,
            initiatorId: initiatorId,
            type: CollaborationType(rawValue: type) ?? .both,
            offeredText: offeredText,
            requestedText: requestedText,
            placeName: placeName,
            guests: guests,
            scheduledFor: scheduledFor,
            contentDeadline: contentDeadline,
            status: DealStatus(rawValue: status) ?? .draft,
            checkedInUserIds: checkedInUserIds,
            cancellationReason: cancellationReason,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

/// Mirrors backend DealReviewRead for JSON decoding (currently unused but required for DTO parsing)
struct DealReviewReadDTO: Decodable, Sendable {
    let reviewerId: String
    let revieweeId: String
    let punctuality: Int?
    let offerMatch: Int?
    let communication: Int?
    let comment: String?
    let createdAt: Date
}

/// Mirrors backend ContentProofRead for JSON decoding (currently unused but required for DTO parsing)
struct ContentProofReadDTO: Decodable, Sendable {
    let submitterId: String
    let postUrl: String
    let screenshotUrl: String?
    let submittedAt: Date
}

struct DealCreateRequest: Encodable, Sendable {
    let partnerId: String
    let type: CollaborationType
    let youOffer: String
    let youReceive: String
    let placeName: String?
    let guests: String
    let dateTime: Date?
    let contentDeadline: Date?

    init(
        partnerId: String,
        type: CollaborationType,
        youOffer: String,
        youReceive: String,
        placeName: String? = nil,
        guests: String = "solo",
        dateTime: Date? = nil,
        contentDeadline: Date? = nil
    ) {
        self.partnerId = partnerId
        self.type = type
        self.youOffer = youOffer
        self.youReceive = youReceive
        self.placeName = placeName
        self.guests = guests
        self.dateTime = dateTime
        self.contentDeadline = contentDeadline
    }
}

// MARK: - Swipe DTOs

struct SwipeRequest: Encodable, Sendable {
    let targetId: String
    let direction: SwipeDirection
}

struct SwipeReadDTO: Decodable, Sendable {
    let id: String
    let actorId: String
    let targetId: String
    let direction: SwipeDirection
    let delivered: Bool
    let createdAt: Date
}

struct MatchReadDTO: Decodable, Sendable {
    let id: String
    let userIds: [String]
    let source: String
    let firstMessageBy: String?
    let createdAt: Date
    let expiresAt: Date?
}

struct SwipeOutcomeDTO: Decodable, Sendable {
    let swipe: SwipeReadDTO
    let match: MatchReadDTO?

    func toSwipeOutcome() -> SwipeOutcome {
        SwipeOutcome(isMatch: match != nil, matchId: match?.id)
    }
}

// MARK: - Content Proof Request

struct ContentProofRequest: Encodable, Sendable {
    let postUrl: String
    let screenshotUrl: String?
}

// MARK: - Empty API Response

struct EmptyAPIResponse: Decodable {}

// MARK: - Deal Cancel Body

struct DealCancelBody: Encodable, Sendable {
    let reason: String
}

// MARK: - Offer Create Request

struct OfferCreateRequest: Encodable, Sendable {
    let title: String
    let type: CollaborationType
    let bloggerReceives: String
    let businessReceives: String
    let slotsTotal: Int
    let photoURL: String
    let expiresAt: Date?
    let preferredBloggerNiche: String?
    let minAudience: String?
    let guests: String?
    let specialConditions: String?
    let isLastMinute: Bool

    init(
        title: String,
        type: CollaborationType,
        bloggerReceives: String,
        businessReceives: String,
        slotsTotal: Int,
        photoURL: String,
        expiresAt: Date? = nil,
        preferredBloggerNiche: String? = nil,
        minAudience: String? = nil,
        guests: String? = nil,
        specialConditions: String? = nil,
        isLastMinute: Bool = false
    ) {
        self.title = title
        self.type = type
        self.bloggerReceives = bloggerReceives
        self.businessReceives = businessReceives
        self.slotsTotal = slotsTotal
        self.photoURL = photoURL
        self.expiresAt = expiresAt
        self.preferredBloggerNiche = preferredBloggerNiche
        self.minAudience = minAudience
        self.guests = guests
        self.specialConditions = specialConditions
        self.isLastMinute = isLastMinute
    }
}
