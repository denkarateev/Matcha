import Foundation

// MARK: - Deal Type

enum DealType: String, CaseIterable, Codable, Hashable {
    case barter = "barter"
    case paid   = "paid"

    var title: String {
        switch self {
        case .barter: "Barter"
        case .paid:   "Paid"
        }
    }
}

// MARK: - Guests

enum DealGuests: String, CaseIterable, Codable, Hashable {
    case solo     = "solo"
    case plusOne  = "plus_one"

    var title: String {
        switch self {
        case .solo:    "Solo"
        case .plusOne: "+1 Guest"
        }
    }
}

// MARK: - Check-in State

struct DealCheckIn: Hashable, Codable {
    var bloggerConfirmed: Bool = false
    var businessConfirmed: Bool = false
    var windowOpensAt: Date?

    var bothConfirmed: Bool { bloggerConfirmed && businessConfirmed }
}

// MARK: - Review Criteria

struct DealReview: Hashable, Codable {
    var punctuality: Int      // 1–5
    var offerMatch: Int       // 1–5
    var communication: Int    // 1–5
    var comment: String?

    var average: Double {
        Double(punctuality + offerMatch + communication) / 3.0
    }
}

// MARK: - Content Proof

struct ContentProof: Hashable, Codable {
    var url: String
    var screenshotPath: String?
    var submittedAt: Date
}

// MARK: - Deal

struct Deal: Identifiable, Hashable {
    let id: UUID
    let partnerName: String
    let title: String
    let scheduledDateText: String
    var scheduledDate: Date?
    var locationName: String?
    let status: DealStatus
    let progressNote: String
    let canRepeat: Bool
    let contentProofStatus: String?

    // New fields
    var dealType: DealType
    var youOffer: String
    var youReceive: String
    var guests: DealGuests
    var contentDeadline: Date?
    var checkIn: DealCheckIn
    var myRole: Role                    // .blogger or .business
    var bloggerReview: DealReview?
    var businessReview: DealReview?
    var contentProof: ContentProof?
    var isMine: Bool                    // did current user create this deal card?

    // MARK: Computed helpers

    var myCheckInDone: Bool {
        myRole == .blogger ? checkIn.bloggerConfirmed : checkIn.businessConfirmed
    }

    var partnerCheckInDone: Bool {
        myRole == .blogger ? checkIn.businessConfirmed : checkIn.bloggerConfirmed
    }

    var myReview: DealReview? {
        myRole == .blogger ? bloggerReview : businessReview
    }

    var partnerReview: DealReview? {
        myRole == .blogger ? businessReview : bloggerReview
    }

    var reviewsReady: Bool {
        bloggerReview != nil && businessReview != nil
    }
}
