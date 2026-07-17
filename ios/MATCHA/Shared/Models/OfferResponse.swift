import Foundation

/// Status of a blogger's response to a business offer.
enum OfferResponseStatus: String, Codable, Sendable, Hashable {
    case pending
    case accepted
    case declined
}

/// A blogger's response to an offer, as returned by `POST /offers/{id}/respond`.
struct OfferResponse: Identifiable, Hashable, Sendable {
    let id: String
    let offerId: String
    let businessId: String
    let bloggerId: String
    let status: OfferResponseStatus
    let message: String?
    let createdAt: Date
    let updatedAt: Date
}

/// Result of responding to an offer: the created response plus the
/// blogger's remaining daily response quota, as reported by the server.
struct OfferRespondResult: Hashable, Sendable {
    let response: OfferResponse
    let remainingResponses: Int
}

/// The blogger's daily response quota, from `GET /offers/response-quota`.
struct OfferResponseQuota: Decodable, Hashable, Sendable {
    let remainingResponses: Int
    let dailyLimit: Int
}
