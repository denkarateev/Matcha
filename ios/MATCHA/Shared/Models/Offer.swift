import Foundation

// MARK: - Audience Tier

enum AudienceTier: String, CaseIterable, Codable, Identifiable, Hashable {
    case any = "Any"
    case nano = "Nano"
    case micro = "Micro"
    case mid = "Mid"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .any: "Any Audience"
        case .nano: "Nano (1K–10K)"
        case .micro: "Micro (10K–100K)"
        case .mid: "Mid (100K–1M)"
        }
    }

    var shortLabel: String { rawValue }

    var title: String {
        switch self {
        case .any:   "Any"
        case .nano:  "Nano"
        case .micro: "Micro"
        case .mid:   "Mid-tier"
        }
    }

    var range: String {
        switch self {
        case .any:   "No minimum"
        case .nano:  "1K – 10K followers"
        case .micro: "10K – 100K followers"
        case .mid:   "100K – 1M followers"
        }
    }
}

// MARK: - Guests Option

enum GuestsOption: String, CaseIterable, Codable, Identifiable, Hashable {
    case solo = "Solo"
    case plusOne = "+1 Guest"

    var id: String { rawValue }
}

// MARK: - Offer

struct Offer: Identifiable, Hashable {
    let id: String
    let businessUserID: String
    let title: String
    let creator: UserProfile
    let type: CollaborationType
    let rewardSummary: String
    let deliverableSummary: String
    let slotsRemaining: Int
    let slotsTotal: Int
    let expiryText: String
    let expiryDate: Date?
    let preferredNiche: String?
    let preferredNiches: [String]
    let minimumAudience: String?
    let audienceTier: AudienceTier
    let isLastMinute: Bool
    let coverURL: URL?
    let respondedCount: Int
    // Extended fields
    let bloggerReceives: String
    let businessReceives: String
    let guests: GuestsOption
    let specialConditions: String?
    let location: String?
    let postedDate: String?

    /// slotsTotal == 0 means unlimited
    var isUnlimitedSlots: Bool { slotsTotal == 0 }

    init(
        id: String = UUID().uuidString,
        businessUserID: String? = nil,
        title: String,
        creator: UserProfile,
        type: CollaborationType,
        rewardSummary: String,
        deliverableSummary: String,
        slotsRemaining: Int,
        slotsTotal: Int = 3,
        expiryText: String,
        expiryDate: Date? = nil,
        preferredNiche: String? = nil,
        preferredNiches: [String] = [],
        minimumAudience: String? = nil,
        audienceTier: AudienceTier = .any,
        isLastMinute: Bool = false,
        coverURL: URL? = nil,
        respondedCount: Int = 0,
        bloggerReceives: String = "",
        businessReceives: String = "",
        guests: GuestsOption = .solo,
        specialConditions: String? = nil,
        location: String? = nil,
        postedDate: String? = nil
    ) {
        self.id = id
        self.businessUserID = businessUserID ?? creator.id.uuidString
        self.title = title
        self.creator = creator
        self.type = type
        self.rewardSummary = rewardSummary
        self.deliverableSummary = deliverableSummary
        self.slotsRemaining = slotsRemaining
        self.slotsTotal = slotsTotal
        self.expiryText = expiryText
        self.expiryDate = expiryDate
        self.preferredNiche = preferredNiche
        self.preferredNiches = preferredNiches.isEmpty && preferredNiche != nil ? [preferredNiche!] : preferredNiches
        self.minimumAudience = minimumAudience
        self.audienceTier = audienceTier
        self.isLastMinute = isLastMinute
        self.coverURL = coverURL
        self.respondedCount = respondedCount
        self.bloggerReceives = bloggerReceives.isEmpty ? rewardSummary : bloggerReceives
        self.businessReceives = businessReceives.isEmpty ? deliverableSummary : businessReceives
        self.guests = guests
        self.specialConditions = specialConditions
        self.location = location
        self.postedDate = postedDate
    }
}
