import Foundation

enum MockSeedData {
    // MARK: - Real Bali Businesses

    static let theLayerCanggu = UserProfile(
        id: UUID(),
        name: "The Lawn Canggu",
        role: .business,
        heroSymbol: "building.2.crop.circle",
        countryCode: "ID",
        audience: "Beach Club / 87K",
        category: .clubBar,
        district: "Canggu",
        niches: ["Food & Drink", "Events & Nightlife", "Lifestyle", "Music", "Photography"],
        languages: ["EN", "ID"],
        bio: "Batu Bolong's original beachfront venue blending sunset cocktails, live DJs and farm-to-glass mixology. We host 200+ creator shoots a year and offer dedicated content hours every morning before doors open.",
        collaborationType: .both,
        rating: 4.8,
        verifiedVisits: 42,
        badges: [.blueCheck],
        subscriptionPlan: .black,
        hasActiveOffer: true,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1551632436-cbf8dd35adfa?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=1000&fit=crop")!
        ],
        verificationLevel: .blueCheck,
        followersCount: 87000
    )

    static let comoCanggu = UserProfile(
        id: UUID(),
        name: "COMO Uma Canggu",
        role: .business,
        heroSymbol: "building.columns.circle.fill",
        countryCode: "ID",
        audience: "Resort / 52K",
        category: .hotelVilla,
        district: "Canggu",
        niches: ["Travel", "Wellness", "Lifestyle", "Food & Drink", "Photography"],
        languages: ["EN", "ID", "JP"],
        bio: "Five-star surf resort featuring an infinity pool overlooking Echo Beach, COMO Shambhala spa and a farm-to-table restaurant. We run a dedicated creator-stay programme with complimentary styling kits and golden-hour access to the rooftop.",
        collaborationType: .both,
        rating: 4.9,
        verifiedVisits: 28,
        badges: [.blueCheck],
        subscriptionPlan: .black,
        hasActiveOffer: true,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&h=1000&fit=crop")!
        ],
        verificationLevel: .blueCheck,
        followersCount: 52000
    )

    static let revolvingDoorSeminyak = UserProfile(
        id: UUID(),
        name: "Motel Mexicola",
        role: .business,
        heroSymbol: "fork.knife.circle.fill",
        countryCode: "ID",
        audience: "Restaurant / 124K",
        category: .restaurantCafe,
        district: "Seminyak",
        niches: ["Food & Drink", "Events & Nightlife", "Lifestyle", "Art & Design", "Music"],
        languages: ["EN", "ID"],
        bio: "Seminyak's most Instagrammed restaurant -- Mexican street food, hand-painted murals and a rooftop bar that turns into a dance floor after dark. Our neon-lit content walls get 500+ creator tags a month.",
        collaborationType: .paid,
        rating: 4.7,
        verifiedVisits: 56,
        badges: [],
        subscriptionPlan: .pro,
        hasActiveOffer: true,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&h=1000&fit=crop")!
        ],
        followersCount: 124000
    )

    // MARK: - Real Bali Bloggers

    static let sarahBali = UserProfile(
        id: UUID(),
        name: "Sarah Adventures",
        role: .blogger,
        heroSymbol: "person.crop.square.filled.and.at.rectangle",
        countryCode: "AU",
        audience: "34K",
        category: nil,
        district: "Uluwatu",
        niches: ["Travel", "Lifestyle", "Food & Drink", "Photography", "Wellness"],
        languages: ["EN"],
        bio: "Australian travel creator based in Uluwatu. I shoot cinematic reels of cliff-top sunsets, hidden waterfalls and local warungs. 8% engagement rate, 22 verified venue visits, and always open to barter or paid collabs.",
        collaborationType: .both,
        rating: 4.9,
        verifiedVisits: 22,
        badges: [.firstDeal],
        subscriptionPlan: .free,
        hasActiveOffer: false,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1528164344705-47542687000d?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&h=1000&fit=crop")!
        ],
        followersCount: 34000
    )

    static let kevinFitness = UserProfile(
        id: UUID(),
        name: "Kevin Wellness",
        role: .blogger,
        heroSymbol: "figure.run.circle.fill",
        countryCode: "DE",
        audience: "18K",
        category: nil,
        district: "Canggu",
        niches: ["Wellness", "Fitness", "Lifestyle", "Travel", "Food & Drink"],
        languages: ["EN", "DE"],
        bio: "German fitness coach creating wellness content across Bali. Daily routines include sunrise surf, cold plunge and jungle yoga. Clean aesthetic with a 12% save rate -- ideal for spa, supplement and activewear brands.",
        collaborationType: .barter,
        rating: 4.6,
        verifiedVisits: 8,
        badges: [],
        subscriptionPlan: .free,
        hasActiveOffer: false,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&h=1000&fit=crop")!
        ],
        followersCount: 18500
    )

    static let mayaPace = UserProfile(
        id: UUID(),
        name: "Maya Pace",
        role: .blogger,
        heroSymbol: "camera.macro.circle.fill",
        countryCode: "FR",
        audience: "12K",
        category: nil,
        district: "Ubud",
        niches: ["Wellness", "Beauty & Fashion", "Lifestyle", "Art & Design", "Photography"],
        languages: ["EN", "FR"],
        bio: "French beauty and skincare creator living in Ubud's rice-field hills. I specialise in spa reviews, clean-beauty flat-lays and high-intent short-form tutorials. New to MATCHA but growing fast with 6% engagement.",
        collaborationType: .paid,
        rating: nil,
        verifiedVisits: 0,
        badges: [.newcomer],
        subscriptionPlan: .free,
        hasActiveOffer: false,
        isVerified: false,
        photoURL: URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=800&h=1000&fit=crop")!
        ],
        followersCount: 12400
    )

    static let lunaYoga = UserProfile(
        id: UUID(),
        name: "Luna Yoga Bali",
        role: .business,
        heroSymbol: "figure.mind.and.body.circle.fill",
        countryCode: "ID",
        audience: "Studio / 21K",
        category: .spaWellness,
        district: "Ubud",
        niches: ["Wellness", "Fitness", "Lifestyle", "Travel", "Photography"],
        languages: ["EN", "ID"],
        bio: "Open-air yoga shala nestled in Ubud's rice terraces. We run daily vinyasa, sound-healing circles and monthly creator retreats with complimentary stays. Perfect backdrop for wellness and travel content.",
        collaborationType: .barter,
        rating: 4.8,
        verifiedVisits: 15,
        badges: [],
        subscriptionPlan: .pro,
        hasActiveOffer: true,
        isVerified: true,
        photoURL: URL(string: "https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&h=1000&fit=crop"),
        photoURLs: [
            URL(string: "https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1545389336-cf090694435e?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1600618528240-fb9fc964b853?w=800&h=1000&fit=crop")!,
            URL(string: "https://images.unsplash.com/photo-1512438248247-f0f2a5a8b7f0?w=800&h=1000&fit=crop")!
        ],
        followersCount: 21000
    )

    // Legacy aliases
    static let surfVilla = comoCanggu
    static let nadia = sarahBali
    static let coconutClub = revolvingDoorSeminyak
    static let maya = mayaPace
    static let fitRetreat = lunaYoga

    static let feedProfiles = [theLayerCanggu, sarahBali, comoCanggu, revolvingDoorSeminyak, kevinFitness, mayaPace, lunaYoga]

    static let offers = [
        Offer(
            id: UUID().uuidString,
            title: "Sunset tasting menu reel",
            creator: revolvingDoorSeminyak,
            type: .paid,
            rewardSummary: "$180 + dinner for two",
            deliverableSummary: "1 Reel, 3 story frames, tags within 48h.",
            slotsRemaining: 2,
            slotsTotal: 3,
            expiryText: "Ends tomorrow",
            preferredNiche: "Food & Drink",
            preferredNiches: ["Food", "Lifestyle"],
            minimumAudience: "10K+",
            audienceTier: .micro,
            isLastMinute: true,
            coverURL: URL(string: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=500&fit=crop"),
            respondedCount: 7,
            bloggerReceives: "$180 cash + complimentary dinner for two guests",
            businessReceives: "1 Reel (min 15s) + 3 story frames with location tag within 48h",
            guests: .plusOne,
            specialConditions: "Must tag @motelmexicola in all content",
            location: "Seminyak",
            postedDate: "2d ago"
        ),
        Offer(
            id: UUID().uuidString,
            title: "Sunrise yoga & breathwork reel",
            creator: lunaYoga,
            type: .barter,
            rewardSummary: "Full retreat day + meals",
            deliverableSummary: "1 carousel, 2 story mentions.",
            slotsRemaining: 4,
            slotsTotal: 5,
            expiryText: "Open",
            preferredNiche: "Wellness",
            preferredNiches: ["Fitness", "Health"],
            minimumAudience: "Any",
            audienceTier: .any,
            isLastMinute: false,
            coverURL: URL(string: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&h=500&fit=crop"),
            respondedCount: 3,
            bloggerReceives: "Full-day retreat pass including meals and treatments",
            businessReceives: "1 carousel post + 2 story mentions with @lunayogabali",
            guests: .solo,
            location: "Ubud",
            postedDate: "1w ago"
        ),
        Offer(
            id: UUID().uuidString,
            title: "Luxury villa creator stay",
            creator: comoCanggu,
            type: .both,
            rewardSummary: "2-night stay + $250 usage rights",
            deliverableSummary: "1 hero reel, 5 photos, repost rights 30 days.",
            slotsRemaining: 1,
            slotsTotal: 2,
            expiryText: "3 days left",
            preferredNiche: "Travel",
            preferredNiches: ["Travel", "Lifestyle"],
            minimumAudience: "25K+",
            audienceTier: .micro,
            isLastMinute: false,
            coverURL: URL(string: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800&h=500&fit=crop"),
            respondedCount: 12,
            bloggerReceives: "2-night villa stay + $250 for photo usage rights",
            businessReceives: "1 hero reel + 5 high-res photos + 30-day repost rights",
            guests: .plusOne,
            specialConditions: "Must have portfolio of previous luxury stays",
            location: "Canggu",
            postedDate: "3d ago"
        ),
        Offer(
            id: UUID().uuidString,
            title: "Beach club launch party",
            creator: theLayerCanggu,
            type: .paid,
            rewardSummary: "$300 + VIP table",
            deliverableSummary: "3 Reels, 10 Stories, event coverage.",
            slotsRemaining: 3,
            slotsTotal: 5,
            expiryText: "5 days left",
            preferredNiche: "Events & Nightlife",
            preferredNiches: ["Lifestyle", "Travel"],
            minimumAudience: "15K+",
            audienceTier: .micro,
            isLastMinute: false,
            coverURL: URL(string: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=800&h=500&fit=crop"),
            respondedCount: 9,
            bloggerReceives: "$300 payment + VIP table for 2 with bottle service",
            businessReceives: "3 Reels + 10 Stories covering opening night",
            guests: .plusOne,
            location: "Canggu",
            postedDate: "Today"
        )
    ]

    // MARK: - Mock Deal Factory

    private static func mockDeal(
        partnerName: String,
        title: String,
        scheduledDateText: String,
        locationName: String? = nil,
        daysOffset: Int = 0,
        status: DealStatus,
        progressNote: String,
        canRepeat: Bool = false,
        contentProofStatus: String? = nil,
        dealType: DealType = .barter,
        youOffer: String = "",
        youReceive: String = "",
        guests: DealGuests = .solo,
        contentDeadline: Date? = nil,
        checkIn: DealCheckIn = DealCheckIn(),
        myRole: Role = .blogger,
        bloggerReview: DealReview? = nil,
        businessReview: DealReview? = nil,
        contentProof: ContentProof? = nil,
        isMine: Bool = true
    ) -> Deal {
        Deal(
            id: UUID(),
            partnerName: partnerName,
            title: title,
            scheduledDateText: scheduledDateText,
            scheduledDate: Calendar.current.date(byAdding: .day, value: daysOffset, to: Date()),
            locationName: locationName,
            status: status,
            progressNote: progressNote,
            canRepeat: canRepeat,
            contentProofStatus: contentProofStatus,
            dealType: dealType,
            youOffer: youOffer,
            youReceive: youReceive,
            guests: guests,
            contentDeadline: contentDeadline,
            checkIn: checkIn,
            myRole: myRole,
            bloggerReview: bloggerReview,
            businessReview: businessReview,
            contentProof: contentProof,
            isMine: isMine
        )
    }

    static let activitySummary = ActivitySummary(
        likes: [sarahBali, mayaPace, kevinFitness],
        activeDeals: [
            mockDeal(
                partnerName: revolvingDoorSeminyak.name,
                title: "Beachfront dinner collab",
                scheduledDateText: "Today, 19:30",
                locationName: "The Lawn Canggu",
                daysOffset: 0,
                status: .confirmed,
                progressNote: "Business checked in. Your turn!",
                dealType: .barter,
                youOffer: "1 Reel + 3 Stories, tagged within 48h",
                youReceive: "Dinner for 2 at sunset table",
                guests: .plusOne,
                contentDeadline: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                checkIn: DealCheckIn(bloggerConfirmed: false, businessConfirmed: true)
            ),
            mockDeal(
                partnerName: comoCanggu.name,
                title: "Villa tour and room reveal",
                scheduledDateText: "Tomorrow, 10:00",
                locationName: "COMO Uma Canggu",
                daysOffset: 1,
                status: .draft,
                progressNote: "Deal card sent, awaiting reply.",
                dealType: .paid,
                youOffer: "1 hero reel + 5 photos, 30-day repost rights",
                youReceive: "2-night stay + $250 usage rights",
                guests: .solo
            )
        ],
        finishedDeals: [
            mockDeal(
                partnerName: "Luma Spa",
                title: "Recovery ritual launch",
                scheduledDateText: "Last week",
                locationName: "Luma Spa Umalas",
                daysOffset: -7,
                status: .reviewed,
                progressNote: "Both reviews published. 4.8 average.",
                canRepeat: true,
                contentProofStatus: "Proof confirmed",
                dealType: .barter,
                youOffer: "1 carousel + 2 story mentions",
                youReceive: "Full spa day treatment",
                checkIn: DealCheckIn(bloggerConfirmed: true, businessConfirmed: true),
                bloggerReview: DealReview(punctuality: 5, offerMatch: 5, communication: 4, comment: "Wonderful experience — exceeded expectations."),
                businessReview: DealReview(punctuality: 4, offerMatch: 5, communication: 5, comment: "Great content, posted on time!"),
                contentProof: ContentProof(url: "https://instagram.com/p/example123", screenshotPath: nil, submittedAt: Date())
            )
        ],
        cancelledDeals: [
            mockDeal(
                partnerName: "Atlas Brunch",
                title: "Brunch feature",
                scheduledDateText: "2 days ago",
                locationName: "Atlas Kitchen Bali",
                daysOffset: -2,
                status: .cancelled,
                progressNote: "Cancelled because of schedule conflict.",
                dealType: .barter,
                youOffer: "1 photo post + story",
                youReceive: "Brunch for 2",
                guests: .plusOne,
                isMine: false
            )
        ],
        noShowDeals: [
            mockDeal(
                partnerName: "Ocean Park",
                title: "Adventure day coverage",
                scheduledDateText: "Monday",
                locationName: "Ocean Park Bali",
                daysOffset: -3,
                status: .noShow,
                progressNote: "You checked in but partner did not. 24h window expired.",
                dealType: .paid,
                youOffer: "3 Reels of adventure activities",
                youReceive: "$200 + park entry",
                checkIn: DealCheckIn(bloggerConfirmed: true, businessConfirmed: false)
            )
        ],
        applications: [
            OfferApplication(
                id: UUID(),
                applicant: sarahBali,
                offerTitle: "Sunset tasting menu reel",
                submittedAt: "12m ago",
                statusText: "Needs response within 72h",
                isActionRequired: true
            ),
            OfferApplication(
                id: UUID(),
                applicant: mayaPace,
                offerTitle: "Sunrise yoga & breathwork reel",
                submittedAt: "Yesterday",
                statusText: "Accepted and converted to a match",
                isActionRequired: false
            )
        ]
    )

    static let chatHome = ChatHome(
        newMatches: [
            NewMatch(profile: sarahBali, matchId: "mock-1", expiresAt: Date().addingTimeInterval(40 * 3600), createdAt: Date().addingTimeInterval(-8 * 3600)),
            NewMatch(profile: comoCanggu, matchId: "mock-2", expiresAt: Date().addingTimeInterval(6 * 3600), createdAt: Date().addingTimeInterval(-42 * 3600)),
            NewMatch(profile: kevinFitness, matchId: "mock-3", expiresAt: Date().addingTimeInterval(47 * 3600), createdAt: Date().addingTimeInterval(-1 * 3600)),
        ],
        conversations: [
            ChatPreview(
                id: UUID(),
                partner: revolvingDoorSeminyak,
                lastMessage: "Deal confirmed. See you at golden hour.",
                timestampText: "Now",
                unreadCount: 2,
                translationNote: "Translated from Indonesian",
                isMuted: false,
                activeDealStatus: .confirmed,
                dealSummary: ChatDealSummary(
                    dealID: UUID().uuidString,
                    title: "Golden hour terrace content",
                    status: .confirmed,
                    detail: "Confirmed for sunset this evening.",
                    cta: .checkIn
                )
            ),
            ChatPreview(
                id: UUID(),
                partner: sarahBali,
                lastMessage: "I can send draft concepts tonight.",
                timestampText: "14:20",
                unreadCount: 0,
                translationNote: nil,
                isMuted: false,
                activeDealStatus: .draft,
                dealSummary: ChatDealSummary(
                    dealID: UUID().uuidString,
                    title: "Dinner + 1 Reel",
                    status: .draft,
                    detail: "Review the terms and accept or decline.",
                    cta: .respond
                )
            ),
            ChatPreview(
                id: UUID(),
                partner: lunaYoga,
                lastMessage: "Muted updates for this chat.",
                timestampText: "Yesterday",
                unreadCount: 0,
                translationNote: nil,
                isMuted: true
            )
        ]
    )

    static func makeCurrentUser(role: Role, name: String, category: BusinessCategory? = .restaurantCafe) -> UserProfile {
        UserProfile(
            id: UUID(),
            name: name,
            role: role,
            heroSymbol: role == .business ? "storefront.circle.fill" : "person.crop.circle.badge.checkmark",
            countryCode: "ID",
            audience: role == .business ? "\(category?.title ?? "Business") / Trial" : "Shadow profile",
            category: role == .business ? category : nil,
            district: "Bali",
            niches: role == .business ? ["Food & Drink", "Lifestyle"] : ["Travel", "Lifestyle"],
            languages: ["EN", "RU"],
            bio: role == .business
                ? "Shadow business account with queued likes and fast access to the match feed."
                : "Shadow creator account with pending likes ready to unlock after verification.",
            collaborationType: .both,
            rating: nil,
            verifiedVisits: 0,
            badges: [.newcomer],
            subscriptionPlan: role == .business ? .pro : .free,
            hasActiveOffer: role == .business,
            isVerified: false
        )
    }
}
