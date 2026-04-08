import Observation
import SwiftUI

struct ChatConversationView: View {
    let repository: any MatchaRepository

    @State private var store: ChatConversationStore
    @State private var messageText = ""
    @State private var showBlockReport = false
    @State private var showPartnerProfile = false
    @State private var showCreateDeal = false
    @State private var selectedDeal: Deal?
    @State private var showReviewSheet = false
    @State private var showCancelDealConfirm = false
    @State private var showNoShowConfirm = false
    @State private var showContentProof = false
    @State private var isDealPipelineCollapsed = false
    @State private var expandedTranslations: Set<String> = []
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(chat: ChatPreview, repository: any MatchaRepository) {
        self.repository = repository
        _store = State(initialValue: ChatConversationStore(chat: chat, repository: repository))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = store.error {
                errorBanner(error)
            }

            if store.shouldPromptCurrentUserToWriteFirst {
                firstMessageCallout(
                    title: "Your move",
                    body: "This match works like Bumble: you open the conversation first, and you have 48 hours to start it."
                )
            } else if store.isWaitingForPartnerFirstMessage {
                firstMessageCallout(
                    title: "Blogger writes first",
                    body: "This match follows Bumble logic. You'll be able to reply as soon as the blogger starts the chat."
                )
            }

            // Collapsible deal pipeline
            if let deal = store.activeDeal {
                if isDealPipelineCollapsed {
                    // Collapsed: mini bar
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isDealPipelineCollapsed = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                            Text("Active Deal: \(deal.status.title)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(MatchaTokens.Colors.surface)
                        .overlay(alignment: .bottom) {
                            Divider().background(MatchaTokens.Colors.outline)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    // Expanded pipeline
                    VStack(spacing: 0) {
                        // Collapse button
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isDealPipelineCollapsed = true
                                }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(width: 32, height: 24)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 4)

                        DealPipelineView(
                            deal: deal,
                            compact: false,
                            onAdvanceStage: { handlePrimaryDealAction(for: deal) },
                            onTapDetails: { selectedDeal = deal },
                            onAcceptDraft: {
                                Task { await store.acceptActiveDeal() }
                            },
                            onDeclineDraft: {
                                Task { await store.declineActiveDeal() }
                            },
                            onReportNoShow: store.canReportNoShow ? {
                                showNoShowConfirm = true
                            } : nil,
                            onCancelDeal: {
                                showCancelDealConfirm = true
                            },
                            isPerformingAction: store.isPerformingDealAction
                        )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }

            messagesList

            if store.hasLoaded && store.messages.isEmpty && !store.isWaitingForPartnerFirstMessage {
                conversationStartersSection
            }

            if store.shouldShowQuickReplies {
                quickRepliesBar
            }

            inputBar
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }

            ToolbarItem(placement: .principal) {
                Button(action: { showPartnerProfile = true }) {
                    HStack(spacing: 8) {
                        // Partner avatar
                        Group {
                            if let url = store.chat.partner.photoURL {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(MatchaTokens.Colors.elevated)
                                    }
                                }
                            } else {
                                ZStack {
                                    Circle().fill(MatchaTokens.Colors.elevated)
                                    Text(String(store.chat.partner.name.prefix(1)).uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(MatchaTokens.Colors.accent)
                                }
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        // Name + status
                        VStack(alignment: .leading, spacing: 1) {
                            Text(store.chat.partner.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                                .lineLimit(1)
                            if let deal = store.activeDeal {
                                Text(deal.status.displayTitle)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(MatchaTokens.Colors.accent)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if store.activeDeal == nil {
                        Button(action: { showCreateDeal = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Deal")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(MatchaTokens.Colors.accent.opacity(0.12), in: Capsule())
                            .overlay(Capsule().strokeBorder(MatchaTokens.Colors.accent.opacity(0.3), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .disabled(!store.canStartDeal)
                        .opacity(store.canStartDeal ? 1 : 0.55)
                        .accessibilityHint("Create a collaboration proposal with dates, deliverables, and terms.")
                    }

                    Menu {
                        Button(action: { showBlockReport = true }) {
                            Label("Block or Report", systemImage: "exclamationmark.shield")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }
                }
            }
        }
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showBlockReport) {
            BlockReportView(
                profile: store.chat.partner,
                onBlock: { dismiss() },
                onReport: {}
            )
        }
        .sheet(isPresented: $showPartnerProfile) {
            NavigationStack {
                ProfileDetailView(profile: store.chat.partner)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showCreateDeal) {
            CreateDealView(
                partnerName: store.chat.partner.name,
                partnerId: store.chat.partner.serverUserId.isEmpty ? store.chat.partner.id.uuidString : store.chat.partner.serverUserId,
                repository: repository
            ) {
                await store.load()
                // If the deal wasn't picked up on first load (backend eventual consistency),
                // retry once after a short delay
                if store.activeDeal == nil {
                    try? await Task.sleep(for: .milliseconds(800))
                    await store.load()
                }
            }
        }
        .sheet(item: $selectedDeal) { deal in
            NavigationStack {
                DealDetailView(repository: repository, onDealUpdated: { _ in
                    Task { await store.load() }
                }, deal: deal)
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let deal = store.activeDeal {
                ReviewDealView(deal: deal) { review in
                    Task {
                        await store.submitReview(
                            DealReviewRequest(
                                punctuality: review.punctuality,
                                offerMatch: review.offerMatch,
                                communication: review.communication,
                                comment: review.comment
                            )
                        )
                        await MainActor.run {
                            showReviewSheet = false
                        }
                    }
                }
            }
        }
        .confirmationDialog("Cancel this deal?", isPresented: $showCancelDealConfirm, titleVisibility: .visible) {
            Button("Cancel Deal", role: .destructive) {
                Task { await store.cancelActiveDeal(reason: "cancelled") }
            }
            Button("Keep Deal", role: .cancel) {}
        } message: {
            Text("This will cancel the active deal. The other party will be notified.")
        }
        .confirmationDialog("Report no-show?", isPresented: $showNoShowConfirm, titleVisibility: .visible) {
            Button("Report No-Show", role: .destructive) {
                Task { await store.markNoShowActiveDeal() }
            }
            Button("Wait Longer", role: .cancel) {}
        } message: {
            Text("This will mark the other party as a no-show. They can rate your punctuality.")
        }
        .sheet(isPresented: $showContentProof) {
            if let deal = store.activeDeal {
                ContentProofView(deal: deal) { proof in
                    Task {
                        await store.submitContentProofForActiveDeal(
                            postUrl: proof.url,
                            screenshotUrl: proof.screenshotPath
                        )
                    }
                    showContentProof = false
                }
            }
        }
        .task {
            await store.loadIfNeeded()
        }
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.body.weight(.medium))
            Text(error.errorDescription ?? "Something went wrong")
                .font(.subheadline)
                .lineLimit(2)
            Spacer()
            Button("Retry") {
                Task { await store.load() }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(MatchaTokens.Colors.accent)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.top, MatchaTokens.Spacing.small)
    }

    private var partnerBar: some View {
        HStack(spacing: 12) {
            avatarView(profile: store.chat.partner, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(store.chat.partner.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    if store.chat.partner.hasBlueCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(MatchaTokens.Colors.baliBlue)
                    }
                }

                if let summary = store.dealSummary {
                    Text(summary.detail)
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)
                } else {
                    Text("Direct chat")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.success)
                }
            }

            Spacer()

            Button(action: { showPartnerProfile = true }) {
                Image(systemName: "info.circle.fill")
                    .font(.body)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(MatchaTokens.Colors.elevated, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            MatchaTokens.Colors.surface
                .overlay(alignment: .bottom) {
                    Rectangle().fill(MatchaTokens.Colors.glassBorder).frame(height: 0.5)
                }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(store.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.vertical, MatchaTokens.Spacing.medium)
            }
            .onChange(of: store.messages.count) { _, _ in
                if let lastID = store.messages.last?.id {
                    withAnimation(MatchaTokens.Animations.cardAppear) {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ message: ConversationMessage) -> some View {
        switch message.body {
        case .text(let text):
            textBubble(text: text, message: message)
        case .system(let text):
            systemBubble(text: text, timestamp: message.createdAt)
        case .deal(let deal):
            dealBubble(deal: deal, message: message)
        case .image(let caption):
            imageBubble(caption: caption, message: message)
        }
    }

    private func textBubble(text: String, message: ConversationMessage) -> some View {
        HStack(alignment: .bottom, spacing: 6) {
            if message.isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 2) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(message.isOutgoing ? .black : .white)

                    Text(shortTime(message.createdAt))
                        .font(.system(size: 10))
                        .foregroundStyle(message.isOutgoing ? .black.opacity(0.5) : .white.opacity(0.35))
                        .padding(.bottom, 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.isOutgoing
                        ? MatchaTokens.Colors.accent
                        : MatchaTokens.Colors.elevated,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            }

            if !message.isOutgoing { Spacer(minLength: 60) }
        }
        .padding(.vertical, 1)
    }

    private func dealBubble(deal: Deal, message: ConversationMessage) -> some View {
        VStack(spacing: 4) {
            DealCardView(
                deal: deal,
                onAccept: {
                    Task { await store.acceptActiveDeal() }
                },
                onDecline: {
                    Task { await store.declineActiveDeal() }
                },
                onViewDetail: {
                    selectedDeal = deal
                }
            )

            Text(shortTime(message.createdAt))
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func imageBubble(caption: String?, message: ConversationMessage) -> some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 60) }

            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(maxWidth: 200)
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.2))
                    }

                if let caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            if !message.isOutgoing { Spacer(minLength: 60) }
        }
        .padding(.vertical, 2)
    }

    private func systemBubble(text: String, timestamp: Date) -> some View {
        HStack(spacing: 6) {
            if text.contains("confirmed") || text.contains("Confirmed") {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.success)
            } else if text.contains("checked in") || text.contains("Checked") {
                Image(systemName: "location.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.baliBlue)
            } else if text.contains("completed") || text.contains("Reviews") {
                Image(systemName: "star.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            } else if text.contains("cancelled") || text.contains("declined") {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.danger)
            }

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(MatchaTokens.Colors.glassFill, in: Capsule())
        .overlay(Capsule().strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func firstMessageCallout(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }

            Text(body)
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.top, MatchaTokens.Spacing.small)
    }

    private var quickRepliesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.quickReplies, id: \.self) { reply in
                    Button {
                        store.dismissQuickReplies()
                        Task {
                            await store.sendMessage(text: reply)
                        }
                    } label: {
                        Text(reply)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(MatchaTokens.Colors.accent.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(MatchaTokens.Colors.accent.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(MatchaTokens.Colors.surface)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MatchaTokens.Colors.outline)

            if store.isWaitingForPartnerFirstMessage {
                lockedInputBar
                    .padding(.horizontal, MatchaTokens.Spacing.medium)
                    .padding(.vertical, 12)
                    .background(MatchaTokens.Colors.background)
                    .padding(.bottom, 8)
            } else {
                HStack(spacing: 8) {
                    // Text field (Telegram style)
                    TextField(
                        "Message...",
                        text: $messageText,
                        axis: .vertical
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                    )

                    // Send button
                    Button(action: sendMessage) {
                        Group {
                            if store.isSending {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(
                                        trimmedMessage.isEmpty ? MatchaTokens.Colors.textMuted : .black
                                    )
                            }
                        }
                        .frame(width: 34, height: 34)
                        .background(
                            trimmedMessage.isEmpty
                                ? Color.clear
                                : MatchaTokens.Colors.accent,
                            in: Circle()
                        )
                    }
                    .disabled(trimmedMessage.isEmpty || store.isSending)
                    .animation(.easeInOut(duration: 0.15), value: trimmedMessage.isEmpty)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(MatchaTokens.Colors.surface)
            }
        }
    }

    private var lockedInputBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.circle.fill")
                .font(.title3)
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.8))

            Text("Blogger writes first in this match")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 18)
    }

    private var trimmedMessage: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var conversationStartersSection: some View {
        VStack(spacing: 8) {
            Text("Break the ice")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            ForEach(conversationStarters, id: \.self) { starter in
                Button {
                    messageText = starter
                    sendMessage()
                } label: {
                    Text(starter)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .liquidGlassPill()
                }
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.bottom, MatchaTokens.Spacing.large)
    }

    private var conversationStarters: [String] {
        let name = store.chat.partner.name
        if store.chat.partner.role == .business {
            return [
                "Hi \(name)! I'd love to learn what kind of content performs best for your venue.",
                "Hey! I think my audience could be a fit. Want me to share a quick concept?",
                "Hi \(name)! Are you open to a collab this week?"
            ]
        }

        return [
            "Hi \(name)! We'd love to discuss a collab that fits your content style.",
            "Hey! Your profile looks strong. Want to review a quick deal idea?",
            "Hi \(name)! Are you available for a collab this week?"
        ]
    }

    private func sendMessage() {
        let text = trimmedMessage
        guard !text.isEmpty, store.canCurrentUserSendFirstMessage else { return }
        messageText = ""
        Task {
            await store.sendMessage(text: text)
        }
    }

    private func handlePrimaryDealAction(for deal: Deal) {
        switch deal.status {
        case .confirmed:
            Task { await store.checkInActiveDeal() }
        case .visited:
            showContentProof = true
        case .noShow:
            showReviewSheet = true
        default:
            selectedDeal = deal
        }
    }

    @ViewBuilder
    private func avatarView(profile: UserProfile, size: CGFloat) -> some View {
        if let url = profile.photoURL {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    initialsCircle(name: profile.name, size: size)
                }
            }
        } else {
            initialsCircle(name: profile.name, size: size)
        }
    }

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(MatchaTokens.Colors.elevated)
                .frame(width: size, height: size)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

}

#Preview {
    NavigationStack {
        ChatConversationView(
            chat: MockSeedData.chatHome.conversations[0],
            repository: MockMatchaRepository()
        )
    }
    .preferredColorScheme(.dark)
}
