import Foundation

struct OfferApplication: Identifiable, Hashable {
    let id: UUID
    let applicant: UserProfile
    let offerTitle: String
    let submittedAt: String
    let statusText: String
    let isActionRequired: Bool
}
