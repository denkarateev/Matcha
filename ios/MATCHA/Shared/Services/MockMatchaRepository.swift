import Foundation

@MainActor
final class MockMatchaRepository: MatchaRepository {

    // MARK: - Feed & Swipe

    func fetchMatchFeed() async throws -> [UserProfile] {
        try await Task.sleep(for: .milliseconds(180))
        return MockSeedData.feedProfiles
    }

    func fetchMatchFeed(filters: FeedFilterParams) async throws -> [UserProfile] {
        try await Task.sleep(for: .milliseconds(180))
        var result = MockSeedData.feedProfiles
        if let niche = filters.niche {
            result = result.filter { $0.niches.contains(niche) }
        }
        if let district = filters.district {
            result = result.filter { $0.district == district }
        }
        if let min = filters.minFollowers {
            result = result.filter { ($0.followersCount ?? 0) >= min }
        }
        if let collab = filters.collabType, let type = CollaborationType(rawValue: collab) {
            result = result.filter { $0.collaborationType == type || $0.collaborationType == .both }
        }
        return result
    }

    func swipe(targetId: String, direction: SwipeDirection) async throws -> SwipeOutcome {
        try await Task.sleep(for: .milliseconds(120))
        // Simulate occasional match on right/super swipe
        let isMatch = direction != .left && Bool.random()
        return SwipeOutcome(isMatch: isMatch, matchId: isMatch ? UUID().uuidString : nil)
    }

    func matchBack(targetId: String) async throws -> MatchBackResult {
        try await Task.sleep(for: .milliseconds(150))
        return MatchBackResult(matchId: UUID().uuidString)
    }

    // MARK: - Profiles

    func fetchProfile(userId: String) async throws -> ProfileRead {
        try await Task.sleep(for: .milliseconds(150))
        // Return a stub ProfileRead built from mock current user
        let user = MockSeedData.nadia
        return stubProfileRead(from: user)
    }

    func updateProfile(_ update: ProfileUpdateRequest) async throws -> ProfileRead {
        try await Task.sleep(for: .milliseconds(200))
        let user = MockSeedData.nadia
        return stubProfileRead(from: user)
    }

    // MARK: - Offers

    func fetchOffers() async throws -> [Offer] {
        try await Task.sleep(for: .milliseconds(180))
        return MockSeedData.offers
    }

    func fetchOffers(filters: OfferFilterParams) async throws -> [Offer] {
        try await Task.sleep(for: .milliseconds(180))
        var result = MockSeedData.offers
        if let type = filters.type, let ct = CollaborationType(rawValue: type) {
            result = result.filter { $0.type == ct }
        }
        if let niche = filters.niche {
            result = result.filter { $0.preferredNiche == niche || $0.preferredNiches.contains(niche) }
        }
        if filters.lastMinuteOnly {
            result = result.filter { $0.isLastMinute }
        }
        return result
    }

    func createOffer(_ request: OfferCreateRequest) async throws -> Offer {
        try await Task.sleep(for: .milliseconds(180))
        return Offer(
            title: request.title,
            creator: MockSeedData.theLayerCanggu,
            type: request.type,
            rewardSummary: request.bloggerReceives,
            deliverableSummary: request.businessReceives,
            slotsRemaining: request.slotsTotal,
            slotsTotal: request.slotsTotal,
            expiryText: request.expiresAt == nil ? "No limit" : "Scheduled",
            expiryDate: request.expiresAt,
            preferredNiche: request.preferredBloggerNiche,
            minimumAudience: request.minAudience,
            isLastMinute: request.isLastMinute,
            coverURL: URL(string: request.photoURL),
            bloggerReceives: request.bloggerReceives,
            businessReceives: request.businessReceives,
            guests: GuestsOption(rawValue: request.guests ?? "") ?? .solo,
            specialConditions: request.specialConditions
        )
    }

    func closeOffer(offerId: String) async throws -> Offer {
        try await Task.sleep(for: .milliseconds(120))
        return MockSeedData.offers.first { $0.id == offerId } ?? MockSeedData.offers[0]
    }

    // MARK: - Activity

    func fetchActivitySummary() async throws -> ActivitySummary {
        try await Task.sleep(for: .milliseconds(180))
        return MockSeedData.activitySummary
    }

    // MARK: - Chats

    func fetchChatHome() async throws -> ChatHome {
        try await Task.sleep(for: .milliseconds(180))
        return MockSeedData.chatHome
    }

    func fetchChatThread(chatId: String) async throws -> ChatThread {
        try await Task.sleep(for: .milliseconds(180))
        let chat = MockSeedData.chatHome.conversations.first(where: { $0.chatID == chatId }) ?? MockSeedData.chatHome.conversations[0]
        let activeDeal = stubDeal(
            chat: chat,
            status: chat.activeDealStatus ?? .draft
        )

        let messages: [ConversationMessage] = [
            ConversationMessage(
                id: UUID().uuidString,
                chatID: chatId,
                senderID: chat.partner.id.uuidString,
                body: .text("Hey! I can send draft concepts tonight."),
                createdAt: Date().addingTimeInterval(-2_400),
                isOutgoing: false
            ),
            ConversationMessage(
                id: UUID().uuidString,
                chatID: chatId,
                senderID: NetworkService.shared.currentUserID ?? UUID().uuidString,
                body: .text("Perfect. Let's align on the deliverables and timing."),
                createdAt: Date().addingTimeInterval(-1_800),
                isOutgoing: true
            ),
            ConversationMessage(
                id: UUID().uuidString,
                chatID: chatId,
                senderID: chat.partner.id.uuidString,
                body: .deal(activeDeal),
                createdAt: Date().addingTimeInterval(-1_200),
                isOutgoing: false
            )
        ]

        return ChatThread(chatID: chatId, messages: messages, activeDeal: activeDeal)
    }

    func sendMessage(chatId: String, request: SendChatMessageRequest) async throws -> ConversationMessage {
        try await Task.sleep(for: .milliseconds(120))
        let sanitized = ValidationService.sanitize(request.text ?? "")
        return ConversationMessage(
            id: UUID().uuidString,
            chatID: chatId,
            senderID: NetworkService.shared.currentUserID ?? UUID().uuidString,
            body: .text(sanitized),
            createdAt: Date(),
            isOutgoing: true
        )
    }

    // MARK: - Quick Replies

    func fetchQuickReplies(chatId: String) async throws -> [String] {
        try await Task.sleep(for: .milliseconds(120))
        return [
            "Hi! I'd love to collaborate",
            "Hey! Love your venue",
            "Interested in a collab?",
        ]
    }

    // MARK: - Chat Actions

    func muteChat(chatId: String) async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    func unmuteChat(chatId: String) async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    func unmatchChat(chatId: String) async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Deals

    func fetchDeals() async throws -> [DealRead] {
        try await Task.sleep(for: .milliseconds(180))
        return []
    }

    func fetchDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead()
    }

    func createDeal(_ request: DealCreateRequest) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(200))
        return stubDealRead()
    }

    func acceptDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .confirmed)
    }

    func declineDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .cancelled)
    }

    func confirmDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .confirmed)
    }

    func checkInDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .visited)
    }

    func submitReview(dealId: String, review: DealReviewRequest) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .reviewed)
    }

    func cancelDeal(dealId: String, reason: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .cancelled)
    }

    func markNoShow(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .noShow)
    }

    func submitContentProof(dealId: String, postUrl: String, screenshotUrl: String?) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead(status: .visited)
    }

    func repeatDeal(dealId: String) async throws -> DealRead {
        try await Task.sleep(for: .milliseconds(150))
        return stubDealRead()
    }

    // MARK: - Account

    func deleteAccount() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    // MARK: - Stubs

    private func stubProfileRead(from profile: UserProfile) -> ProfileRead {
        ProfileRead(
            userId: profile.id.uuidString,
            role: profile.role.rawValue,
            displayName: profile.name,
            photoUrls: [],
            primaryPhotoUrl: "",
            country: profile.countryCode,
            instagramHandle: nil,
            tiktokHandle: nil,
            audienceSize: nil,
            category: profile.category?.rawValue,
            district: profile.district,
            website: nil,
            niches: profile.niches,
            languages: profile.languages,
            bio: profile.bio,
            description: nil,
            whatWeOffer: nil,
            nationality: nil,
            residence: nil,
            gender: nil,
            birthday: nil,
            collabType: profile.collaborationType.rawValue,
            badges: profile.badges.map { $0.rawValue },
            verifiedVisits: profile.verifiedVisits,
            rating: profile.rating,
            reviewCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func stubDealRead(status: DealStatus = .draft) -> DealRead {
        DealRead(
            id: UUID().uuidString,
            chatId: UUID().uuidString,
            participantIds: [],
            initiatorId: "",
            type: .both,
            offeredText: "",
            requestedText: "",
            placeName: "Canggu Beach",
            guests: "solo",
            scheduledFor: nil,
            contentDeadline: nil,
            status: status,
            checkedInUserIds: [],
            cancellationReason: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func stubDeal(chat: ChatPreview, status: DealStatus) -> Deal {
        Deal(
            id: UUID(),
            partnerName: chat.partner.name,
            title: chat.dealSummary?.title ?? "Dinner + 1 Reel",
            scheduledDateText: "Apr 5, 19:30",
            scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            locationName: "Canggu Beach",
            status: status,
            progressNote: chat.dealSummary?.detail ?? "Awaiting response",
            canRepeat: status == .reviewed,
            contentProofStatus: nil,
            dealType: .barter,
            youOffer: "1 Reel + 3 Stories",
            youReceive: "Dinner for 2",
            guests: .plusOne,
            contentDeadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            checkIn: DealCheckIn(bloggerConfirmed: status == .visited || status == .reviewed, businessConfirmed: status == .reviewed),
            myRole: .blogger,
            bloggerReview: status == .reviewed ? DealReview(punctuality: 5, offerMatch: 5, communication: 5, comment: "Smooth collab") : nil,
            businessReview: nil,
            contentProof: nil,
            isMine: false
        )
    }
}
