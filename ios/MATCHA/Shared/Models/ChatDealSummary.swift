import Foundation

enum ChatDealCTA: String, Hashable {
    case respond
    case checkIn
    case leaveReview

    var title: String {
        switch self {
        case .respond:
            return "Respond"
        case .checkIn:
            return "Check In"
        case .leaveReview:
            return "Leave Review"
        }
    }

    var iconName: String {
        switch self {
        case .respond:
            return "person.2.circle.fill"
        case .checkIn:
            return "location.fill"
        case .leaveReview:
            return "star.fill"
        }
    }
}

struct ChatDealSummary: Hashable {
    let dealID: String
    let title: String
    let status: DealStatus
    let detail: String
    let cta: ChatDealCTA?
}

extension ChatDealSummary {
    static func from(deal: Deal) -> ChatDealSummary {
        let detail: String
        let cta: ChatDealCTA?

        switch deal.status {
        case .draft:
            detail = deal.isMine
                ? "Waiting for \(deal.partnerName) to confirm."
                : "Review the terms and accept or decline."
            cta = deal.isMine ? nil : .respond
        case .confirmed:
            detail = "Confirmed for \(deal.scheduledDateText)."
            cta = .checkIn
        case .visited:
            detail = deal.reviewsReady
                ? "Both reviews are in."
                : "Collab completed. Finalize the review."
            cta = deal.myReview == nil ? .leaveReview : nil
        case .reviewed:
            detail = "Deal completed and reviewed."
            cta = nil
        case .cancelled:
            detail = "This deal was cancelled."
            cta = nil
        case .noShow:
            detail = "A no-show was reported for this collab."
            cta = deal.myReview == nil ? .leaveReview : nil
        }

        return ChatDealSummary(
            dealID: deal.id.uuidString,
            title: deal.title.isEmpty ? "Deal update" : deal.title,
            status: deal.status,
            detail: detail,
            cta: cta
        )
    }
}
