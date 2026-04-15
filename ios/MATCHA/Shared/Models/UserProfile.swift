import Foundation

// MARK: - VerificationLevel

/// Mirrors backend VerificationLevel int enum
enum VerificationLevel: Int, Codable, Hashable, Sendable {
    case shadow   = 0
    case verified = 1
    case blueCheck = 2

    var isVerified: Bool { self.rawValue >= VerificationLevel.verified.rawValue }
}

// MARK: - SwipeDirection

/// Mirrors backend SwipeDirection string enum
enum SwipeDirection: String, Codable, Hashable, Sendable {
    case left   = "left"
    case right  = "right"
    case `super` = "super"
}

// MARK: - UserProfile

/// Core domain model.
/// When decoded from API it maps the backend `ProfileRead` schema.
/// When constructed locally (mock, onboarding) it uses default values.
struct UserProfile: Identifiable, Hashable {
    let id: UUID
    /// The raw server-side user ID (e.g. "business-1", "blogger-2", or a real UUID string).
    /// Use this for API calls instead of `id.uuidString`.
    var serverUserId: String = ""
    let name: String
    let role: Role
    let heroSymbol: String         // SF Symbol name — local only, derived from role/category
    let countryCode: String
    let audience: String           // Human-readable audience string, derived locally
    let category: BusinessCategory?
    let district: String?
    let niches: [String]
    let languages: [String]
    let bio: String
    let collaborationType: CollaborationType
    let rating: Double?
    let verifiedVisits: Int
    let badges: [ProfileBadge]
    let subscriptionPlan: SubscriptionPlan
    let hasActiveOffer: Bool
    let isVerified: Bool
    let photoURL: URL?
    let photoURLs: [URL]

    // MARK: Additional API fields
    let verificationLevel: VerificationLevel
    let locationDistrict: String?
    let completedCollabsCount: Int
    let collabTypes: [CollaborationType]
    let followersCount: Int?
    let instagramHandle: String?
    let tiktokHandle: String?
    var youtubeHandle: String?
    var nationality: String?
    var residence: String?
    var gender: String?
    var birthday: Date?
    var instagramFollowers: Int?
    var instagramEngagement: Double?  // percentage
    var youtubeSubscribers: Int?
    var tiktokFollowers: Int?

    var secondaryLine: String {
        category?.title ?? role.title
    }

    /// True when at least one social account handle is linked.
    var hasSocialAccounts: Bool {
        instagramHandle != nil || youtubeHandle != nil || tiktokHandle != nil
    }

    /// Blue Check: awarded for 3+ completed deals with Content Proof.
    var hasBlueCheck: Bool {
        verificationLevel == .blueCheck || badges.contains(.blueCheck)
    }

    // MARK: - Memberwise init for mock/local use
    init(
        id: UUID,
        name: String,
        role: Role,
        heroSymbol: String,
        countryCode: String,
        audience: String,
        category: BusinessCategory?,
        district: String?,
        niches: [String],
        languages: [String],
        bio: String,
        collaborationType: CollaborationType,
        rating: Double?,
        verifiedVisits: Int,
        badges: [ProfileBadge],
        subscriptionPlan: SubscriptionPlan,
        hasActiveOffer: Bool,
        isVerified: Bool,
        photoURL: URL? = nil,
        photoURLs: [URL] = [],
        verificationLevel: VerificationLevel = .shadow,
        locationDistrict: String? = nil,
        completedCollabsCount: Int = 0,
        collabTypes: [CollaborationType] = [],
        followersCount: Int? = nil,
        nationality: String? = nil,
        residence: String? = nil,
        gender: String? = nil,
        birthday: Date? = nil,
        instagramHandle: String? = nil,
        tiktokHandle: String? = nil,
        youtubeHandle: String? = nil,
        instagramFollowers: Int? = nil,
        instagramEngagement: Double? = nil,
        youtubeSubscribers: Int? = nil,
        tiktokFollowers: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.heroSymbol = heroSymbol
        self.countryCode = countryCode
        self.audience = audience
        self.category = category
        self.district = district
        self.niches = niches
        self.languages = languages
        self.bio = bio
        self.collaborationType = collaborationType
        self.rating = rating
        self.verifiedVisits = verifiedVisits
        self.badges = badges
        self.subscriptionPlan = subscriptionPlan
        self.hasActiveOffer = hasActiveOffer
        self.isVerified = isVerified
        self.photoURL = photoURL
        self.photoURLs = photoURLs
        self.verificationLevel = verificationLevel
        self.locationDistrict = locationDistrict
        self.completedCollabsCount = completedCollabsCount
        self.collabTypes = collabTypes
        self.nationality = nationality
        self.residence = residence
        self.gender = gender
        self.birthday = birthday
        self.followersCount = followersCount
        self.instagramHandle = instagramHandle
        self.tiktokHandle = tiktokHandle
        self.youtubeHandle = youtubeHandle
        self.instagramFollowers = instagramFollowers
        self.instagramEngagement = instagramEngagement
        self.youtubeSubscribers = youtubeSubscribers
        self.tiktokFollowers = tiktokFollowers
    }
}

// MARK: - API Mapping

extension UserProfile {

    /// Creates a UserProfile from a backend `ProfileRead` response and the associated `AuthUser`.
    /// The backend stores profile data (display_name, niches, etc.) separately from user data (role, plan, etc.).
    static func from(profile: ProfileRead, user: AuthUser) -> UserProfile {
        let derivedRole = user.role
        let derivedCategory = profile.category.flatMap { BusinessCategory(rawValue: $0) }
        let derivedCollabType = CollaborationType(rawValue: profile.collabType) ?? .both
        let derivedBadges = profile.badges.compactMap { ProfileBadge(rawValue: $0) }
        let audienceString = profile.audienceSize.map { "\($0)" } ?? "—"

        var up = UserProfile(
            id: UUID(uuidString: profile.userId) ?? UUID(),
            name: profile.displayName,
            role: derivedRole,
            heroSymbol: derivedRole == .business ? "storefront.circle.fill" : "person.crop.circle.badge.checkmark",
            countryCode: profile.country ?? "ID",
            audience: audienceString,
            category: derivedCategory,
            district: profile.district,
            niches: profile.niches,
            languages: profile.languages,
            bio: profile.bio ?? "",
            collaborationType: derivedCollabType,
            rating: profile.rating,
            verifiedVisits: profile.verifiedVisits,
            badges: derivedBadges,
            subscriptionPlan: user.planTier,
            hasActiveOffer: false,
            isVerified: user.verificationLevel.isVerified,
            photoURL: URL(string: profile.primaryPhotoUrl),
            photoURLs: profile.photoUrls.compactMap { URL(string: $0) },
            verificationLevel: user.verificationLevel,
            locationDistrict: profile.district,
            completedCollabsCount: profile.reviewCount,
            collabTypes: [derivedCollabType],
            followersCount: profile.audienceSize,
            instagramHandle: profile.instagramHandle,
            tiktokHandle: profile.tiktokHandle,
            youtubeHandle: nil,
            instagramFollowers: profile.audienceSize,  // fallback: use audienceSize
            instagramEngagement: nil,
            youtubeSubscribers: nil,
            tiktokFollowers: nil
        )
        up.serverUserId = profile.userId
        return up
    }

    /// Creates a UserProfile from a backend `ProfileRead` alone (public profile view, no auth context).
    /// Uses the `role` field from the API response when available.
    static func from(profile: ProfileRead) -> UserProfile {
        let resolvedRole = profile.role.flatMap { Role(rawValue: $0) } ?? .blogger
        return from(profile: profile, role: resolvedRole)
    }

    static func from(
        profile: ProfileRead,
        role: Role,
        subscriptionPlan: SubscriptionPlan = .free,
        verificationLevel: VerificationLevel = .shadow
    ) -> UserProfile {
        let derivedCategory = profile.category.flatMap { BusinessCategory(rawValue: $0) }
        let derivedCollabType = CollaborationType(rawValue: profile.collabType) ?? .both
        let derivedBadges = profile.badges.compactMap { ProfileBadge(rawValue: $0) }
        let audienceString = profile.audienceSize.map { "\($0)" } ?? "—"

        var up = UserProfile(
            id: UUID(uuidString: profile.userId) ?? UUID(),
            name: profile.displayName,
            role: role,
            heroSymbol: role == .business ? "storefront.circle.fill" : "person.crop.circle.badge.checkmark",
            countryCode: profile.country ?? "ID",
            audience: audienceString,
            category: derivedCategory,
            district: profile.district,
            niches: profile.niches,
            languages: profile.languages,
            bio: profile.bio ?? "",
            collaborationType: derivedCollabType,
            rating: profile.rating,
            verifiedVisits: profile.verifiedVisits,
            badges: derivedBadges,
            subscriptionPlan: subscriptionPlan,
            hasActiveOffer: role == .business,
            isVerified: verificationLevel.isVerified || derivedBadges.contains(.verified) || derivedBadges.contains(.blueCheck),
            photoURL: URL(string: profile.primaryPhotoUrl),
            photoURLs: profile.photoUrls.compactMap { URL(string: $0) },
            verificationLevel: verificationLevel,
            locationDistrict: profile.district,
            completedCollabsCount: profile.reviewCount,
            collabTypes: [derivedCollabType],
            followersCount: profile.audienceSize,
            instagramHandle: profile.instagramHandle,
            tiktokHandle: profile.tiktokHandle,
            youtubeHandle: nil,
            instagramFollowers: profile.audienceSize,  // fallback: use audienceSize
            instagramEngagement: nil,
            youtubeSubscribers: nil,
            tiktokFollowers: nil
        )
        up.serverUserId = profile.userId
        return up
    }
}

// MARK: - ProfileRead (API DTO)

/// Mirrors backend `ProfileRead` Pydantic schema for JSON decoding.
struct ProfileRead: Decodable, Sendable {
    let userId: String
    let role: String?
    let displayName: String
    let photoUrls: [String]
    let primaryPhotoUrl: String
    let country: String?
    let instagramHandle: String?
    let tiktokHandle: String?
    let audienceSize: Int?
    let category: String?
    let district: String?
    let website: String?
    let niches: [String]
    let languages: [String]
    let bio: String?
    let description: String?
    let whatWeOffer: String?
    let nationality: String?
    let residence: String?
    let gender: String?
    let birthday: String?
    let collabType: String
    let badges: [String]
    let verifiedVisits: Int
    let rating: Double?
    let reviewCount: Int
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - ProfileUpdateRequest (outgoing)

struct ProfileUpdateRequest: Encodable {
    var displayName: String?
    var photoUrls: [String]?
    var primaryPhotoUrl: String?
    var country: String?
    var nationality: String?
    var residence: String?
    var gender: String?
    var birthday: String?
    var instagramHandle: String?
    var tiktokHandle: String?
    var audienceSize: Int?
    var category: String?
    var district: String?
    var website: String?
    var niches: [String]?
    var languages: [String]?
    var bio: String?
    var description: String?
    var whatWeOffer: String?
    var collabType: String?
}
