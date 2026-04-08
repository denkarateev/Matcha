import Foundation

/// Production implementation of MatchaRepository that talks to the FastAPI backend.
@MainActor
final class APIMatchaRepository: MatchaRepository {

    private let network: NetworkService

    init(network: NetworkService = .shared) {
        self.network = network
    }

    // MARK: - Feed & Swipe

    func fetchMatchFeed() async throws -> [UserProfile] {
        let session = try await resolveCurrentSession()
        let profiles: [ProfileRead] = try await network.request(.GET, path: "/matches/feed")
        let fallbackRole = counterpartRole(for: session.role)
        return profiles.map {
            let resolvedRole = $0.role.flatMap { Role(rawValue: $0) } ?? fallbackRole
            return UserProfile.from(
                profile: $0,
                role: resolvedRole,
                verificationLevel: .verified
            )
        }
    }

    func swipe(targetId: String, direction: SwipeDirection) async throws -> SwipeOutcome {
        let body = SwipeRequest(targetId: targetId, direction: direction)
        let outcome: SwipeOutcomeDTO = try await network.request(.POST, path: "/matches/swipes", body: body)
        return outcome.toSwipeOutcome()
    }

    func matchBack(targetId: String) async throws -> MatchBackResult {
        struct MatchBackBody: Encodable { let target_id: String }
        struct MatchBackResponse: Decodable { let match: MatchReadDTO }
        let response: MatchBackResponse = try await network.request(
            .POST, path: "/matches/match-back", body: MatchBackBody(target_id: targetId)
        )
        return MatchBackResult(matchId: response.match.id)
    }

    // MARK: - Profiles

    func fetchProfile(userId: String) async throws -> ProfileRead {
        try await network.request(.GET, path: "/profiles/\(userId)")
    }

    func updateProfile(_ update: ProfileUpdateRequest) async throws -> ProfileRead {
        try await network.request(.PUT, path: "/profiles/me", body: update)
    }

    // MARK: - Offers

    func fetchOffers() async throws -> [Offer] {
        let dtos: [OfferReadDTO] = try await network.request(.GET, path: "/offers")
        return dtos.map { $0.toDomain() }
    }

    func createOffer(_ request: OfferCreateRequest) async throws -> Offer {
        let dto: OfferReadDTO = try await network.request(.POST, path: "/offers", body: request)
        return dto.toDomain()
    }

    func closeOffer(offerId: String) async throws -> Offer {
        let dto: OfferReadDTO = try await network.request(.POST, path: "/offers/\(offerId)/close")
        return dto.toDomain()
    }

    // MARK: - Activity

    func fetchActivitySummary() async throws -> ActivitySummary {
        let session = try await resolveCurrentSession()
        let summary: ActivitySummaryDTO = try await network.request(.GET, path: "/activity/summary")
        let counterpart = counterpartRole(for: session.role)

        let allDeals = summary.activeDeals + summary.finishedDeals + summary.cancelledDeals + summary.noShowDeals
        let partnerIDs = Set(
            allDeals.compactMap { counterpartID(for: $0.participantIds, currentUserID: session.userID) }
        )
        let profilesByID = try await fetchProfiles(
            userIDs: Array(partnerIDs),
            assumedRole: counterpart
        )

        let likes = summary.likes.map { like in
            makeLikeProfile(from: like, assumedRole: counterpart)
        }

        let offerDTOs: [OfferReadDTO]
        do {
            offerDTOs = try await network.request(.GET, path: "/offers")
        } catch {
            offerDTOs = []
        }
        let offerTitlesByID = Dictionary(offerDTOs.map { ($0.id, $0.title) }, uniquingKeysWith: { _, last in last })

        let applicationProfileIDs = Set(summary.applications.map {
            session.role == .business ? $0.bloggerId : $0.businessId
        })
        let applicationProfiles = try await fetchProfiles(
            userIDs: Array(applicationProfileIDs),
            assumedRole: session.role == .business ? .blogger : .business
        )

        return ActivitySummary(
            likes: likes,
            activeDeals: summary.activeDeals.map {
                makeActivityDeal(from: $0, session: session, profilesByID: profilesByID)
            },
            finishedDeals: summary.finishedDeals.map {
                makeActivityDeal(from: $0, session: session, profilesByID: profilesByID)
            },
            cancelledDeals: summary.cancelledDeals.map {
                makeActivityDeal(from: $0, session: session, profilesByID: profilesByID)
            },
            noShowDeals: summary.noShowDeals.map {
                makeActivityDeal(from: $0, session: session, profilesByID: profilesByID)
            },
            applications: summary.applications.map {
                makeOfferApplication(
                    from: $0,
                    session: session,
                    offerTitlesByID: offerTitlesByID,
                    profilesByID: applicationProfiles
                )
            }
        )
    }

    // MARK: - Chats

    func fetchChatHome() async throws -> ChatHome {
        let session = try await resolveCurrentSession()

        async let matchDTOs: [MatchReadDTO] = network.request(.GET, path: "/matches")
        async let chatDTOs: [ChatReadDTO] = network.request(.GET, path: "/chats")

        // Deals may fail/cancel independently — don't let it break chats
        let dealDTOs: [DealReadDTO]
        do {
            dealDTOs = try await network.request(.GET, path: "/deals")
        } catch {
            dealDTOs = [] // graceful fallback — chats still load
        }

        let (matches, chats) = try await (matchDTOs, chatDTOs)
        let deals = dealDTOs
        print("[MATCHA] fetchChatHome: \(chats.count) chats, \(matches.count) matches, \(deals.count) deals, session=\(session.userID)")
        // Use reduce to avoid crash on duplicate keys
        var matchesByID: [String: MatchReadDTO] = [:]
        for match in matches { matchesByID[match.id] = match }
        let counterpartIDs = Set(
            chats.compactMap { counterpartID(for: $0.participantIds, currentUserID: session.userID) } +
            matches.compactMap { counterpartID(for: $0.userIds, currentUserID: session.userID) }
        )
        let profilesByID = try await fetchProfiles(
            userIDs: Array(counterpartIDs),
            assumedRole: counterpartRole(for: session.role)
        )
        let dealsByChatID = Dictionary(grouping: deals, by: \.chatId)

        let conversations = chats
            .sorted { $0.updatedAt > $1.updatedAt }
            .map { chat in
                let partnerID = counterpartID(for: chat.participantIds, currentUserID: session.userID) ?? chat.id
                let partner = profilesByID[partnerID] ?? makePlaceholderProfile(
                    id: partnerID,
                    role: counterpartRole(for: session.role),
                    name: "Matcha User"
                )
                let match = chat.matchId.flatMap { matchesByID[$0] }
                let deal = preferredDeal(
                    from: dealsByChatID[chat.id, default: []],
                    partnerName: partner.name,
                    session: session
                )
                let dealSummary = deal.map(ChatDealSummary.from)
                let isAwaitingFirstMessage = abs(chat.updatedAt.timeIntervalSince(chat.createdAt)) < 1 && dealSummary == nil

                return ChatPreview(
                    id: UUID(uuidString: chat.id) ?? UUID(),
                    chatID: chat.id,
                    partner: partner,
                    lastMessage: dealSummary?.detail
                        ?? starterPrompt(
                            for: match,
                            currentUserID: session.userID,
                            isAwaitingFirstMessage: isAwaitingFirstMessage
                        )
                        ?? "Open conversation",
                    timestampText: relativeTimestamp(for: chat.updatedAt),
                    unreadCount: 0,
                    translationNote: nil,
                    isMuted: chat.mutedUserIds.contains(session.userID),
                    activeDealStatus: dealSummary?.status,
                    dealSummary: dealSummary,
                    matchId: chat.matchId,
                    matchSource: match?.source,
                    firstMessageByUserId: match?.firstMessageBy,
                    createdAt: chat.createdAt,
                    isAwaitingFirstMessage: isAwaitingFirstMessage,
                    matchExpiresAt: match?.expiresAt
                )
            }

        // Deduplicate: skip if already in conversations OR already seen in this list
        let conversationPartnerIDs = Set(conversations.map { $0.partner.id.uuidString.lowercased() })
        var seenMatchPartnerIDs = Set<String>()
        let newMatches = matches.compactMap { match -> UserProfile? in
            guard let partnerID = counterpartID(for: match.userIds, currentUserID: session.userID) else {
                return nil
            }
            let lowered = partnerID.lowercased()
            guard !conversationPartnerIDs.contains(lowered) else { return nil }
            guard seenMatchPartnerIDs.insert(lowered).inserted else { return nil }
            return profilesByID[partnerID]
        }

        return ChatHome(newMatches: newMatches, conversations: conversations)
    }

    func fetchChatThread(chatId: String) async throws -> ChatThread {
        let session = try await resolveCurrentSession()

        async let chatDetail: ChatDetailDTO = network.request(.GET, path: "/chats/\(chatId)")

        // Deals may fail independently — don't let it break the thread (mirrors fetchChatHome pattern)
        let deals: [DealReadDTO]
        do {
            deals = try await network.request(.GET, path: "/deals")
        } catch {
            deals = [] // graceful fallback — messages still load without deals
        }

        let detail = try await chatDetail
        let partnerID = counterpartID(for: Array(detail.participantIds), currentUserID: session.userID) ?? detail.id
        let partnerName = (try? await fetchProfile(userId: partnerID))?.displayName ?? "Partner"

        var matchedDTOs = deals.filter { $0.chatId == chatId }
        if matchedDTOs.isEmpty {
            // Fallback: match by participants when chatId doesn't line up
            let partnerIds = Set(detail.participantIds).subtracting([session.userID])
            matchedDTOs = deals.filter { deal in
                let dealParticipants = Set(deal.participantIds)
                return dealParticipants.contains(session.userID) && !dealParticipants.isDisjoint(with: partnerIds)
            }
        }
        print("[MATCHA] fetchChatThread: chatId=\(chatId), deals=\(deals.count), threadDeals=\(matchedDTOs.count)")

        let threadDeals = matchedDTOs
            .map { makeDeal(from: $0, partnerName: partnerName, session: session) }
            .sorted { $0.scheduledDate ?? .distantPast > $1.scheduledDate ?? .distantPast }

        let dealLookup = Dictionary(threadDeals.map { ($0.id.uuidString, $0) }, uniquingKeysWith: { _, last in last })
        let messages = detail.messages.map {
            makeConversationMessage(from: $0, currentUserID: session.userID, dealLookup: dealLookup)
        }

        return ChatThread(
            chatID: chatId,
            messages: messages,
            activeDeal: preferredDeal(from: threadDeals)
        )
    }

    func sendMessage(chatId: String, request: SendChatMessageRequest) async throws -> ConversationMessage {
        let session = try await resolveCurrentSession()
        let sanitizedText: String?
        if let text = request.text {
            sanitizedText = try ValidationService.validateMessage(text)
        } else {
            sanitizedText = nil
        }
        let sanitizedRequest = SendChatMessageRequest(
            text: sanitizedText,
            imageURL: request.imageURL,
            dealCardId: request.dealCardId
        )

        var activeChatId = chatId

        let dto: MessageReadDTO = try await network.request(
            .POST,
            path: "/chats/\(activeChatId)/messages",
            body: sanitizedRequest
        )
        return makeConversationMessage(from: dto, currentUserID: session.userID, dealLookup: [:])
    }

    // MARK: - Quick Replies

    func fetchQuickReplies(chatId: String) async throws -> [String] {
        let response: QuickRepliesResponse = try await network.request(
            .GET, path: "/chats/\(chatId)/quick-replies"
        )
        return response.replies
    }

    // MARK: - Chat Actions

    func muteChat(chatId: String) async throws {
        let _: EmptyAPIResponse = try await network.request(.POST, path: "/chats/\(chatId)/mute")
    }

    func unmuteChat(chatId: String) async throws {
        let _: EmptyAPIResponse = try await network.request(.POST, path: "/chats/\(chatId)/unmute")
    }

    func unmatchChat(chatId: String) async throws {
        let _: EmptyAPIResponse = try await network.request(.POST, path: "/chats/\(chatId)/unmatch")
    }

    // MARK: - Deals

    func fetchDeals() async throws -> [DealRead] {
        let dtos: [DealReadDTO] = try await network.request(.GET, path: "/deals")
        return dtos.map { $0.toDomain() }
    }

    func fetchDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.GET, path: "/deals/\(id)")
        return dto.toDomain()
    }

    func createDeal(_ request: DealCreateRequest) async throws -> DealRead {
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals", body: request)
        return dto.toDomain()
    }

    func acceptDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/accept")
        return dto.toDomain()
    }

    func declineDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/decline")
        return dto.toDomain()
    }

    func confirmDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/confirm")
        return dto.toDomain()
    }

    func checkInDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/check-in")
        return dto.toDomain()
    }

    func submitReview(dealId: String, review: DealReviewRequest) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/rate", body: review)
        return dto.toDomain()
    }

    func cancelDeal(dealId: String, reason: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let body = DealCancelBody(reason: reason)
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/cancel", body: body)
        return dto.toDomain()
    }

    func markNoShow(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/no-show")
        return dto.toDomain()
    }

    func submitContentProof(dealId: String, postUrl: String, screenshotUrl: String?) async throws -> DealRead {
        let id = dealId.lowercased()
        let body = ContentProofRequest(postUrl: postUrl, screenshotUrl: screenshotUrl)
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/content-proof", body: body)
        return dto.toDomain()
    }

    func repeatDeal(dealId: String) async throws -> DealRead {
        let id = dealId.lowercased()
        let dto: DealReadDTO = try await network.request(.POST, path: "/deals/\(id)/repeat")
        return dto.toDomain()
    }

    // MARK: - Account

    func deleteAccount() async throws {
        try await network.requestVoid(.DELETE, path: "/auth/me")
    }

    // MARK: - Private helpers

    private func resolveCurrentSession() async throws -> CurrentSession {
        guard network.authToken != nil else {
            throw NetworkError.unauthorized
        }

        if let userID = network.currentUserID, let role = network.currentUserRole {
            return CurrentSession(userID: userID, role: role)
        }

        let user: AuthUser = try await network.request(.GET, path: "/auth/me")
        network.updateAuthenticatedUser(user)
        return CurrentSession(userID: user.id, role: user.role)
    }

    private func fetchProfiles(userIDs: [String], assumedRole: Role) async throws -> [String: UserProfile] {
        var profiles: [String: UserProfile] = [:]
        for userID in userIDs {
            do {
                let profile = try await fetchProfile(userId: userID)
                profiles[userID] = UserProfile.from(profile: profile, role: assumedRole)
            } catch {
                profiles[userID] = makePlaceholderProfile(id: userID, role: assumedRole, name: "Matcha User")
            }
        }
        return profiles
    }

    private func preferredDeal(
        from dtos: [DealReadDTO],
        partnerName: String,
        session: CurrentSession
    ) -> Deal? {
        let mappedDeals = dtos.map { makeDeal(from: $0, partnerName: partnerName, session: session) }
        return preferredDeal(from: mappedDeals)
    }

    private func preferredDeal(from deals: [Deal]) -> Deal? {
        deals.first {
            $0.status == .draft || $0.status == .confirmed || $0.status == .visited || $0.status == .noShow
        }
    }

    private func starterPrompt(
        for match: MatchReadDTO?,
        currentUserID: String,
        isAwaitingFirstMessage: Bool
    ) -> String? {
        guard
            isAwaitingFirstMessage,
            let match,
            match.source == "swipe",
            let firstMessageBy = match.firstMessageBy
        else {
            return nil
        }

        return firstMessageBy == currentUserID
            ? "Your move. Say hi within 48h."
            : "Blogger writes first."
    }

    private func makeDeal(from dto: DealReadDTO, partnerName: String, session: CurrentSession) -> Deal {
        let partnerID = counterpartID(for: dto.participantIds, currentUserID: session.userID) ?? ""
        let bloggerID = session.role == .blogger ? session.userID : partnerID
        let businessID = session.role == .business ? session.userID : partnerID
        let reviews = reviews(for: dto, bloggerID: bloggerID, businessID: businessID)

        return Deal(
            id: UUID(uuidString: dto.id) ?? UUID(),
            partnerName: partnerName,
            title: ValidationService.sanitize(dto.offeredText),
            scheduledDateText: scheduleLabel(for: dto.scheduledFor),
            scheduledDate: dto.scheduledFor,
            locationName: sanitizedPlaceName(dto.placeName),
            status: DealStatus(rawValue: dto.status) ?? .draft,
            progressNote: ValidationService.sanitize(dto.requestedText),
            canRepeat: dto.status == DealStatus.reviewed.rawValue,
            contentProofStatus: dto.contentProofs?.isEmpty == false ? "Submitted" : nil,
            dealType: dto.type == CollaborationType.paid.rawValue ? .paid : .barter,
            youOffer: ValidationService.sanitize(dto.offeredText),
            youReceive: ValidationService.sanitize(dto.requestedText),
            guests: dto.guests == DealGuests.plusOne.rawValue ? .plusOne : .solo,
            contentDeadline: dto.contentDeadline,
            checkIn: DealCheckIn(
                bloggerConfirmed: dto.checkedInUserIds.contains(bloggerID),
                businessConfirmed: dto.checkedInUserIds.contains(businessID)
            ),
            myRole: session.role,
            bloggerReview: reviews.blogger,
            businessReview: reviews.business,
            contentProof: dto.contentProofs?.first.map {
                ContentProof(
                    url: $0.postUrl,
                    screenshotPath: $0.screenshotUrl,
                    submittedAt: $0.submittedAt
                )
            },
            isMine: dto.initiatorId == session.userID
        )
    }

    private func reviews(
        for dto: DealReadDTO,
        bloggerID: String,
        businessID: String
    ) -> (blogger: DealReview?, business: DealReview?) {
        var bloggerReview: DealReview?
        var businessReview: DealReview?

        for review in dto.reviews ?? [] {
            let mappedReview = DealReview(
                punctuality: review.punctuality ?? 0,
                offerMatch: review.offerMatch ?? 0,
                communication: review.communication ?? 0,
                comment: review.comment
            )
            if review.reviewerId == bloggerID {
                bloggerReview = mappedReview
            } else if review.reviewerId == businessID {
                businessReview = mappedReview
            }
        }

        return (bloggerReview, businessReview)
    }

    private func makeConversationMessage(
        from dto: MessageReadDTO,
        currentUserID: String,
        dealLookup: [String: Deal]
    ) -> ConversationMessage {
        let body: ConversationMessageBody

        if dto.isSystem || dto.messageType == "system" {
            body = .system(ValidationService.sanitize(dto.text))
        } else if let dealCardID = dto.dealCardId, let deal = dealLookup[dealCardID] {
            if shouldRenderInlineDealCard(for: deal) {
                body = .deal(deal)
            } else {
                body = .system(dealSystemMessage(for: deal))
            }
        } else if dto.imageUrl != nil {
            let caption = ValidationService.sanitize(dto.text)
            body = .image(caption: caption.isEmpty ? nil : caption)
        } else {
            body = .text(ValidationService.sanitize(dto.text))
        }

        return ConversationMessage(
            id: dto.id,
            chatID: dto.chatId,
            senderID: dto.senderId,
            body: body,
            createdAt: dto.createdAt,
            isOutgoing: dto.senderId == currentUserID
        )
    }

    private func shouldRenderInlineDealCard(for deal: Deal) -> Bool {
        deal.status == .draft
    }

    private func dealSystemMessage(for deal: Deal) -> String {
        switch deal.status {
        case .draft:
            return "Deal proposed: \(deal.title)"
        case .confirmed:
            return "Deal confirmed for \(deal.scheduledDateText)"
        case .visited:
            return "Visit completed. Reviews are next."
        case .reviewed:
            return "Deal completed and reviewed."
        case .cancelled:
            return "Deal cancelled."
        case .noShow:
            return "No-show recorded for this deal."
        }
    }

    private func makeLegacyDeal(from deal: DealRead, currentUserID: String) -> Deal {
        Deal(
            id: UUID(uuidString: deal.id) ?? UUID(),
            partnerName: deal.participantIds.first(where: { $0 != currentUserID }) ?? "Partner",
            title: deal.offeredText,
            scheduledDateText: scheduleLabel(for: deal.scheduledFor),
            scheduledDate: deal.scheduledFor,
            locationName: sanitizedPlaceName(deal.placeName),
            status: deal.status,
            progressNote: deal.requestedText,
            canRepeat: deal.status == .reviewed,
            contentProofStatus: nil,
            dealType: deal.type == .paid ? .paid : .barter,
            youOffer: deal.offeredText,
            youReceive: deal.requestedText,
            guests: deal.guests == DealGuests.plusOne.rawValue ? .plusOne : .solo,
            contentDeadline: deal.contentDeadline,
            checkIn: DealCheckIn(),
            myRole: network.currentUserRole ?? .blogger,
            bloggerReview: nil,
            businessReview: nil,
            contentProof: nil,
            isMine: deal.initiatorId == currentUserID
        )
    }

    private func makeActivityDeal(
        from dto: DealReadDTO,
        session: CurrentSession,
        profilesByID: [String: UserProfile]
    ) -> Deal {
        let partnerID = counterpartID(for: dto.participantIds, currentUserID: session.userID) ?? ""
        let partnerName = profilesByID[partnerID]?.name ?? "Partner"
        return makeDeal(from: dto, partnerName: partnerName, session: session)
    }

    private func sanitizedPlaceName(_ placeName: String?) -> String? {
        guard let placeName else { return nil }
        let sanitized = ValidationService.sanitize(placeName).trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.isEmpty ? nil : sanitized
    }

    private func makeLikeProfile(from dto: LikeReadDTO, assumedRole: Role) -> UserProfile {
        UserProfile(
            id: UUID(uuidString: dto.userId) ?? UUID(),
            name: dto.displayName,
            role: assumedRole,
            heroSymbol: assumedRole == .business ? "storefront.circle.fill" : "person.crop.circle.badge.checkmark",
            countryCode: "ID",
            audience: dto.audienceSize.map { "\($0)" } ?? "—",
            category: nil,
            district: dto.district,
            niches: dto.niches,
            languages: [],
            bio: "",
            collaborationType: .both,
            rating: nil,
            verifiedVisits: 0,
            badges: dto.isVerified ? [.verified] : [],
            subscriptionPlan: .free,
            hasActiveOffer: assumedRole == .business,
            isVerified: dto.isVerified,
            photoURL: URL(string: dto.primaryPhotoUrl),
            photoURLs: dto.primaryPhotoUrl.isEmpty ? [] : [URL(string: dto.primaryPhotoUrl)].compactMap { $0 },
            verificationLevel: dto.isVerified ? .verified : .shadow,
            locationDistrict: dto.district,
            completedCollabsCount: 0,
            collabTypes: [.both],
            followersCount: dto.audienceSize
        )
    }

    private func makeOfferApplication(
        from dto: OfferResponseReadDTO,
        session: CurrentSession,
        offerTitlesByID: [String: String],
        profilesByID: [String: UserProfile]
    ) -> OfferApplication {
        let applicantID = session.role == .business ? dto.bloggerId : dto.businessId
        let fallbackRole: Role = session.role == .business ? .blogger : .business
        let applicant = profilesByID[applicantID] ?? makePlaceholderProfile(
            id: applicantID,
            role: fallbackRole,
            name: "Matcha User"
        )

        return OfferApplication(
            id: UUID(uuidString: dto.id) ?? UUID(),
            applicant: applicant,
            offerTitle: offerTitlesByID[dto.offerId] ?? "Offer response",
            submittedAt: relativeTimestamp(for: dto.createdAt),
            statusText: applicationStatusText(dto.status, for: session.role),
            isActionRequired: session.role == .business && dto.status == "pending"
        )
    }

    private func applicationStatusText(_ status: String, for role: Role) -> String {
        switch status {
        case "pending":
            return role == .business ? "Reply needed" : "Awaiting response"
        case "accepted":
            return "Accepted"
        case "declined":
            return "Declined"
        default:
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func scheduleLabel(for date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func relativeTimestamp(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func counterpartID(for userIDs: [String], currentUserID: String) -> String? {
        userIDs.first(where: { $0 != currentUserID })
    }

    private func counterpartRole(for role: Role) -> Role {
        role == .blogger ? .business : .blogger
    }

    private func makePlaceholderProfile(id: String, role: Role, name: String) -> UserProfile {
        UserProfile(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            role: role,
            heroSymbol: role == .business ? "storefront.circle.fill" : "person.crop.circle.badge.checkmark",
            countryCode: "ID",
            audience: "—",
            category: nil,
            district: nil,
            niches: [],
            languages: [],
            bio: "",
            collaborationType: .both,
            rating: nil,
            verifiedVisits: 0,
            badges: [],
            subscriptionPlan: .free,
            hasActiveOffer: role == .business,
            isVerified: false
        )
    }
}

// MARK: - Session

private struct CurrentSession {
    let userID: String
    let role: Role
}

// MARK: - Activity DTOs

private struct LikeReadDTO: Decodable, Sendable {
    let userId: String
    let displayName: String
    let primaryPhotoUrl: String
    let district: String?
    let audienceSize: Int?
    let niches: [String]
    let isVerified: Bool
}

private struct OfferResponseReadDTO: Decodable, Sendable {
    let id: String
    let offerId: String
    let businessId: String
    let bloggerId: String
    let status: String
    let message: String?
    let createdAt: Date
    let updatedAt: Date
}

private struct ActivitySummaryDTO: Decodable, Sendable {
    let likes: [LikeReadDTO]
    let activeDeals: [DealReadDTO]
    let finishedDeals: [DealReadDTO]
    let cancelledDeals: [DealReadDTO]
    let noShowDeals: [DealReadDTO]
    let applications: [OfferResponseReadDTO]
}

// MARK: - Offer DTO

struct OfferReadDTO: Decodable, Sendable {
    let id: String
    let businessId: String
    let title: String
    let type: String
    let bloggerReceives: String
    let businessReceives: String
    let slotsTotal: Int
    let slotsRemaining: Int
    let photoUrl: String
    let expiresAt: Date?
    let preferredBloggerNiche: String?
    let minAudience: String?
    let guests: String?
    let specialConditions: String?
    let isLastMinute: Bool
    let status: String
    let createdAt: Date
    let updatedAt: Date

    func toDomain() -> Offer {
        let collabType: CollaborationType = {
            switch type {
            case "barter": return .barter
            case "paid": return .paid
            default: return .both
            }
        }()

        let expiryText: String = {
            guard let date = expiresAt else { return "No limit" }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return "Ends " + formatter.localizedString(for: date, relativeTo: Date())
        }()

        let placeholderCreator = UserProfile(
            id: UUID(uuidString: businessId) ?? UUID(),
            name: "Business",
            role: .business,
            heroSymbol: "storefront.circle.fill",
            countryCode: "ID",
            audience: "—",
            category: nil,
            district: nil,
            niches: [],
            languages: [],
            bio: "",
            collaborationType: collabType,
            rating: nil,
            verifiedVisits: 0,
            badges: [],
            subscriptionPlan: .free,
            hasActiveOffer: true,
            isVerified: false
        )

        return Offer(
            id: id,
            businessUserID: businessId,
            title: title,
            creator: placeholderCreator,
            type: collabType,
            rewardSummary: bloggerReceives,
            deliverableSummary: businessReceives,
            slotsRemaining: slotsRemaining,
            slotsTotal: slotsTotal,
            expiryText: expiryText,
            expiryDate: expiresAt,
            preferredNiche: preferredBloggerNiche,
            minimumAudience: minAudience,
            isLastMinute: isLastMinute,
            coverURL: URL(string: photoUrl),
            bloggerReceives: bloggerReceives,
            businessReceives: businessReceives,
            guests: GuestsOption(rawValue: guests ?? "") ?? .solo,
            specialConditions: specialConditions
        )
    }
}

// MARK: - Chat DTOs

struct QuickRepliesResponse: Decodable, Sendable {
    let replies: [String]
}

struct ChatReadDTO: Decodable, Sendable {
    let id: String
    let participantIds: [String]
    let matchId: String?
    let mutedUserIds: Set<String>
    let createdAt: Date
    let updatedAt: Date
}

struct MessageReadDTO: Decodable, Sendable {
    let id: String
    let chatId: String
    let senderId: String
    let text: String
    let mediaUrls: [String]
    let imageUrl: String?
    let dealCardId: String?
    let isSystem: Bool
    let messageType: String
    let createdAt: Date
}

struct ChatDetailDTO: Decodable, Sendable {
    let id: String
    let participantIds: [String]
    let matchId: String?
    let mutedUserIds: Set<String>
    let createdAt: Date
    let updatedAt: Date
    let messages: [MessageReadDTO]
}
