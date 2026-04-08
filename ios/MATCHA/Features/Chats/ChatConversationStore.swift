import Foundation
import Observation

private struct ChatCreateResponse: Decodable {
    let id: String
}

private struct ChatCreateRequest: Encodable {
    let partnerId: String
}

@MainActor
@Observable
final class ChatConversationStore {
    private let repository: any MatchaRepository

    var chat: ChatPreview
    var thread: ChatThread
    var error: NetworkError?
    var hasLoaded = false
    var isLoading = false
    var isSending = false
    var isPerformingDealAction = false
    var quickReplies: [String] = []
    var quickRepliesDismissed = false
    private var sentMessageCount = 0

    init(chat: ChatPreview, repository: any MatchaRepository) {
        self.chat = chat
        self.repository = repository
        self.thread = ChatThread(chatID: chat.chatID, messages: [], activeDeal: nil)
    }

    var messages: [ConversationMessage] { thread.messages }
    var activeDeal: Deal? { thread.activeDeal }
    var dealSummary: ChatDealSummary? { activeDeal.map(ChatDealSummary.from) ?? chat.dealSummary }
    var hasParticipantMessages: Bool {
        thread.messages.contains { message in
            switch message.body {
            case .system:
                return false
            default:
                return true
            }
        }
    }
    var canCurrentUserSendFirstMessage: Bool {
        guard
            chat.isSwipeMatch,
            chat.isAwaitingFirstMessage,
            !hasParticipantMessages,
            let firstMessageByUserId = chat.firstMessageByUserId,
            let currentUserID = NetworkService.shared.currentUserID
        else {
            return true
        }
        return firstMessageByUserId == currentUserID
    }
    var shouldPromptCurrentUserToWriteFirst: Bool {
        chat.isSwipeMatch && chat.isAwaitingFirstMessage && !hasParticipantMessages && canCurrentUserSendFirstMessage
    }
    var isWaitingForPartnerFirstMessage: Bool {
        chat.isSwipeMatch && chat.isAwaitingFirstMessage && !hasParticipantMessages && !canCurrentUserSendFirstMessage
    }
    var canStartDeal: Bool {
        guard activeDeal == nil else { return false }
        if chat.isSwipeMatch && chat.isAwaitingFirstMessage && !hasParticipantMessages {
            return false
        }
        return true
    }

    var shouldShowQuickReplies: Bool {
        !quickRepliesDismissed && !quickReplies.isEmpty && sentMessageCount < 3
    }

    func loadQuickReplies() async {
        guard !chat.chatID.isEmpty else { return }
        do {
            let replies = try await repository.fetchQuickReplies(chatId: chat.chatID)
            quickReplies = replies
        } catch {
            quickReplies = []
        }
    }

    func dismissQuickReplies() {
        quickRepliesDismissed = true
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        isLoading = true
        error = nil
        hasLoaded = true

        do {
            // Ensure chat exists on server (for new matches without a chat yet)
            let partnerId = chat.partner.serverUserId ?? chat.partner.id.uuidString.lowercased()
            let ensured: ChatCreateResponse = try await NetworkService.shared.request(
                .POST,
                path: "/chats",
                body: ChatCreateRequest(partnerId: partnerId)
            )
            let activeChatId = ensured.id
            chat = ChatPreview(
                id: chat.id, chatID: activeChatId, partner: chat.partner,
                lastMessage: chat.lastMessage, timestampText: chat.timestampText,
                unreadCount: chat.unreadCount, translationNote: chat.translationNote,
                isMuted: chat.isMuted, activeDealStatus: chat.activeDealStatus,
                dealSummary: chat.dealSummary, matchId: chat.matchId,
                matchSource: chat.matchSource, firstMessageByUserId: chat.firstMessageByUserId,
                createdAt: chat.createdAt, isAwaitingFirstMessage: chat.isAwaitingFirstMessage
            )

            let loadedThread = try await repository.fetchChatThread(chatId: activeChatId)
            // Deduplicate messages by ID
            var seenIDs = Set<String>()
            let uniqueMessages = loadedThread.messages.filter { seenIDs.insert($0.id).inserted }
            thread = ChatThread(
                chatID: loadedThread.chatID,
                messages: uniqueMessages,
                activeDeal: loadedThread.activeDeal.map(applyPartnerContext)
            )
            refreshChatSummary(timestamp: chat.timestampText)

            // Load quick replies after thread is available
            await loadQuickReplies()
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }

    func sendMessage(text: String) async {
        guard !isSending else { return }

        do {
            let sanitizedText = try ValidationService.validateMessage(text)
            isSending = true

            // Ensure chat exists on server (creates if needed for new matches)
            var chatId = chat.chatID
            let partnerId = chat.partner.serverUserId ?? chat.partner.id.uuidString.lowercased()
            let ensuredChat: ChatCreateResponse = try await NetworkService.shared.request(
                .POST,
                path: "/chats",
                body: ChatCreateRequest(partnerId: partnerId)
            )
            chatId = ensuredChat.id
            thread = ChatThread(chatID: chatId, messages: thread.messages, activeDeal: thread.activeDeal)

            let message = try await repository.sendMessage(
                chatId: chatId,
                request: SendChatMessageRequest(text: sanitizedText)
            )
            appendMessage(message)
            updateChatLastMessage(sanitizedText)
            sentMessageCount += 1
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch let validationError as ValidationError {
            self.error = .domainError(code: "invalid_message", message: validationError.localizedDescription)
        } catch {
            self.error = .networkError(error)
        }

        isSending = false
    }

    func acceptActiveDeal() async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            let read = try await repository.acceptDeal(dealId: deal.id.uuidString)
            let updatedDeal = makeDeal(from: read, fallback: deal)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: updatedDeal)
            appendSystemMessage("Deal confirmed for \(updatedDeal.scheduledDateText)")
            refreshChatSummary(timestamp: "Now")
        }
    }

    func declineActiveDeal() async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            _ = try await repository.declineDeal(dealId: deal.id.uuidString)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: nil)
            appendSystemMessage("Deal declined")
            clearChatSummary()
        }
    }

    func checkInActiveDeal() async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            let read = try await repository.checkInDeal(dealId: deal.id.uuidString)
            let updatedDeal = makeDeal(from: read, fallback: deal)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: updatedDeal)
            appendSystemMessage(updatedDeal.status == .visited ? "Both sides checked in." : "Check-in recorded.")
            refreshChatSummary(timestamp: "Now")
        }
    }

    func submitReview(_ review: DealReviewRequest) async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            let read = try await repository.submitReview(dealId: deal.id.uuidString, review: review)
            let updatedDeal = makeDeal(from: read, fallback: deal)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: updatedDeal)
            appendSystemMessage(updatedDeal.status == .reviewed ? "Reviews submitted. Deal closed." : "Review submitted.")
            refreshChatSummary(timestamp: "Now")
        }
    }

    func cancelActiveDeal(reason: String) async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            _ = try await repository.cancelDeal(dealId: deal.id.uuidString, reason: reason)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: nil)
            appendSystemMessage("Deal cancelled")
            clearChatSummary()
        }
    }

    func markNoShowActiveDeal() async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            let read = try await repository.markNoShow(dealId: deal.id.uuidString)
            let updatedDeal = makeDeal(from: read, fallback: deal)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: updatedDeal)
            appendSystemMessage("No-show reported")
            refreshChatSummary(timestamp: "Now")
        }
    }

    func submitContentProofForActiveDeal(postUrl: String, screenshotUrl: String?) async {
        guard let deal = activeDeal, !isPerformingDealAction else { return }
        await performDealAction {
            let read = try await repository.submitContentProof(
                dealId: deal.id.uuidString,
                postUrl: postUrl,
                screenshotUrl: screenshotUrl
            )
            let updatedDeal = makeDeal(from: read, fallback: deal)
            thread = ChatThread(chatID: thread.chatID, messages: thread.messages, activeDeal: updatedDeal)
            appendSystemMessage("Content proof submitted")
            refreshChatSummary(timestamp: "Now")
        }
    }

    var canReportNoShow: Bool {
        guard let deal = activeDeal, deal.status == .confirmed else { return false }
        return deal.myCheckInDone && !deal.partnerCheckInDone
    }

    private func performDealAction(_ action: () async throws -> Void) async {
        isPerformingDealAction = true
        error = nil

        do {
            try await action()
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .networkError(error)
        }

        isPerformingDealAction = false
    }

    private func appendMessage(_ message: ConversationMessage) {
        // Deduplicate — don't add if message with same ID already exists
        guard !thread.messages.contains(where: { $0.id == message.id }) else { return }
        thread = ChatThread(
            chatID: thread.chatID,
            messages: thread.messages + [message],
            activeDeal: thread.activeDeal
        )
    }

    private func appendSystemMessage(_ text: String) {
        let message = ConversationMessage(
            id: UUID().uuidString,
            chatID: chat.chatID,
            senderID: NetworkService.shared.currentUserID ?? chat.partner.id.uuidString,
            body: .system(text),
            createdAt: Date(),
            isOutgoing: false
        )
        appendMessage(message)
    }

    private func updateChatLastMessage(_ text: String) {
        chat = copyChatPreview(
            lastMessage: text,
            timestampText: "Now",
            activeDealStatus: chat.activeDealStatus,
            dealSummary: chat.dealSummary,
            isAwaitingFirstMessage: false
        )
    }

    private func refreshChatSummary(timestamp: String) {
        let summary = thread.activeDeal.map(ChatDealSummary.from)
        chat = copyChatPreview(
            lastMessage: summary?.detail ?? chat.lastMessage,
            timestampText: timestamp,
            activeDealStatus: summary?.status,
            dealSummary: summary,
            isAwaitingFirstMessage: false
        )
    }

    private func clearChatSummary() {
        chat = copyChatPreview(
            lastMessage: "Deal update sent",
            timestampText: "Now",
            activeDealStatus: nil,
            dealSummary: nil,
            isAwaitingFirstMessage: false
        )
    }

    private func copyChatPreview(
        lastMessage: String,
        timestampText: String,
        activeDealStatus: DealStatus?,
        dealSummary: ChatDealSummary?,
        isAwaitingFirstMessage: Bool
    ) -> ChatPreview {
        ChatPreview(
            id: chat.id,
            chatID: chat.chatID,
            partner: chat.partner,
            lastMessage: lastMessage,
            timestampText: timestampText,
            unreadCount: chat.unreadCount,
            translationNote: chat.translationNote,
            isMuted: chat.isMuted,
            activeDealStatus: activeDealStatus,
            dealSummary: dealSummary,
            matchId: chat.matchId,
            matchSource: chat.matchSource,
            firstMessageByUserId: chat.firstMessageByUserId,
            createdAt: chat.createdAt,
            isAwaitingFirstMessage: isAwaitingFirstMessage
        )
    }

    private func applyPartnerContext(to deal: Deal) -> Deal {
        Deal(
            id: deal.id,
            partnerName: chat.partner.name,
            title: deal.title,
            scheduledDateText: deal.scheduledDateText,
            scheduledDate: deal.scheduledDate,
            locationName: deal.locationName,
            status: deal.status,
            progressNote: deal.progressNote,
            canRepeat: deal.canRepeat,
            contentProofStatus: deal.contentProofStatus,
            dealType: deal.dealType,
            youOffer: deal.youOffer,
            youReceive: deal.youReceive,
            guests: deal.guests,
            contentDeadline: deal.contentDeadline,
            checkIn: deal.checkIn,
            myRole: deal.myRole,
            bloggerReview: deal.bloggerReview,
            businessReview: deal.businessReview,
            contentProof: deal.contentProof,
            isMine: deal.isMine
        )
    }

    private func makeDeal(from read: DealRead, fallback: Deal) -> Deal {
        let currentUserID = NetworkService.shared.currentUserID
        let updatedCheckIn: DealCheckIn = {
            guard let currentUserID else { return fallback.checkIn }
            let currentUserCheckedIn = read.checkedInUserIds.contains(currentUserID)
            return fallback.myRole == .blogger
                ? DealCheckIn(
                    bloggerConfirmed: currentUserCheckedIn,
                    businessConfirmed: read.checkedInUserIds.count > (currentUserCheckedIn ? 1 : 0)
                )
                : DealCheckIn(
                    bloggerConfirmed: read.checkedInUserIds.count > (currentUserCheckedIn ? 1 : 0),
                    businessConfirmed: currentUserCheckedIn
                )
        }()

        return Deal(
            id: UUID(uuidString: read.id) ?? fallback.id,
            partnerName: chat.partner.name,
            title: ValidationService.sanitize(read.offeredText),
            scheduledDateText: read.scheduledFor.map { formatScheduleDate($0) } ?? "",
            scheduledDate: read.scheduledFor,
            locationName: fallback.locationName ?? read.placeName,
            status: read.status,
            progressNote: ValidationService.sanitize(read.requestedText),
            canRepeat: read.status == .reviewed,
            contentProofStatus: fallback.contentProofStatus,
            dealType: read.type == .paid ? .paid : .barter,
            youOffer: ValidationService.sanitize(read.offeredText),
            youReceive: ValidationService.sanitize(read.requestedText),
            guests: read.guests == DealGuests.plusOne.rawValue ? .plusOne : .solo,
            contentDeadline: read.contentDeadline,
            checkIn: updatedCheckIn,
            myRole: fallback.myRole,
            bloggerReview: fallback.bloggerReview,
            businessReview: fallback.businessReview,
            contentProof: fallback.contentProof,
            isMine: read.initiatorId == currentUserID
        )
    }

    private func formatScheduleDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
