import Observation
import SwiftUI

struct ChatsView: View {
    @State private var store: ChatsStore
    @State private var searchText = ""
    private let repository: any MatchaRepository

    // Actions
    @State private var unmatchTarget: ChatPreview? = nil
    @State private var showUnmatchConfirm = false
    @State private var reportTarget: ChatPreview? = nil
    @State private var showReport = false
    @State private var checkInTarget: ChatPreview? = nil

    // Paywall
    @State private var showPaywall = false

    init(repository: any MatchaRepository) {
        self.repository = repository
        _store = State(initialValue: ChatsStore(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Error banner
                if let error = store.error, store.home.conversations.isEmpty, store.home.newMatches.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.body.weight(.medium))
                        Text(error.errorDescription ?? "Connection error")
                            .font(.subheadline)
                            .lineLimit(3)
                        Spacer()
                        Button("Retry") { Task { await store.load() } }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, MatchaTokens.Spacing.medium)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, MatchaTokens.Spacing.large)
                }

                // Action Needed removed — info already visible in chat rows below

                // Likes + new matches row (always show — Likes card is always visible)
                newMatchesSection
                    .padding(.bottom, MatchaTokens.Spacing.large)

                // Conversations
                if !filteredConversations.isEmpty {
                    conversationsList
                } else if store.hasLoaded {
                    emptyChatsState
                        .padding(.top, 60)
                }
            }
            .padding(.top, MatchaTokens.Spacing.small)
        }
        .refreshable { await store.load() }
        .onAppear {
            guard store.hasLoaded else { return }
            Task { await store.load() }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.inline)
        // Search bar removed — not needed at MVP stage
        // Navigation destinations
        .navigationDestination(for: UserProfile.self) { profile in
            ProfileDetailView(profile: profile)
        }
        .navigationDestination(for: ChatPreview.self) { chat in
            ChatConversationView(chat: chat, repository: repository)
        }
        .navigationDestination(for: ChatsNavDestination.self) { dest in
            switch dest {
            case .likes(let profiles):
                LikesListView(profiles: profiles)
            }
        }
        .confirmationDialog(
            "Unmatch with \(unmatchTarget?.partner.name ?? "")?",
            isPresented: $showUnmatchConfirm,
            titleVisibility: .visible
        ) {
            Button("Unmatch", role: .destructive) {
                if let target = unmatchTarget {
                    Task { await store.unmatch(chat: target) }
                }
                unmatchTarget = nil
            }
            Button("Cancel", role: .cancel) {
                unmatchTarget = nil
            }
        } message: {
            Text("This will remove the match and delete your conversation. This cannot be undone.")
        }
        .task {
            await store.loadIfNeeded()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(.blurredLikes)
        }
        .sheet(isPresented: $showReport) {
            if let target = reportTarget {
                BlockReportView(profile: target.partner)
            }
        }
    }

    private var filteredConversations: [ChatPreview] {
        if searchText.isEmpty {
            return store.home.conversations
        }
        return store.home.conversations.filter {
            $0.partner.name.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessage.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - New Matches (Instagram Stories Style)

    private var actionRequiredSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            HStack {
                Text("Action Needed")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Spacer()
                Text("\(store.home.actionRequiredConversations.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MatchaTokens.Colors.accent, in: Capsule())
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.home.actionRequiredConversations) { chat in
                        NavigationLink(value: chat) {
                            actionRequiredCard(chat)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
            }
        }
    }

    private func actionRequiredCard(_ chat: ChatPreview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Group {
                    if let url = chat.partner.photoURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                rowAvatarPlaceholder(chat.partner)
                            }
                        }
                    } else {
                        rowAvatarPlaceholder(chat.partner)
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.partner.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(1)
                    Text(chat.dealSummary?.detail ?? "Review the latest deal update")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            }

            HStack {
                if let summary = chat.dealSummary {
                    DealStatusBadge(status: summary.status, compact: true)
                }
                Spacer()
                if let cta = chat.dealSummary?.cta {
                    Label(cta.title, systemImage: cta.iconName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, MatchaTokens.Spacing.small)
                        .padding(.vertical, MatchaTokens.Spacing.xSmall)
                        .background(MatchaTokens.Colors.accent, in: Capsule())
                }
            }
        }
        .padding(14)
        .frame(width: 250, alignment: .leading)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
        )
    }

    /// Only matches where no messages have been exchanged yet
    private var uncontactedMatches: [UserProfile] {
        store.home.newMatches.filter { profile in
            guard let chat = matchedConversation(for: profile) else { return true }
            return chat.isAwaitingFirstMessage
        }
    }

    private var newMatchesSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            Text("New Matches")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .padding(.horizontal, MatchaTokens.Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Likes card — navigates to LikesListView
                    Button {
                        showPaywall = true
                    } label: {
                        likesStoryCard
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View people who liked you")
                    .accessibilityHint("See all profiles that liked you")

                    // Only show uncontacted matches (awaiting first message)
                    ForEach(uncontactedMatches) { profile in
                        if let chat = matchedConversation(for: profile) {
                            NavigationLink(value: chat) {
                                matchStoryCard(profile, chat: chat)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("New match: \(profile.name)")
                            .accessibilityHint("Open chat with \(profile.name)")
                        } else {
                            NavigationLink(value: profile) {
                                matchStoryCard(profile, chat: nil)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("New match: \(profile.name)")
                            .accessibilityHint("View \(profile.name)'s profile")
                        }
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
            }
        }
    }

    private var likesStoryCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MatchaTokens.Colors.accent, MatchaTokens.Colors.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)

                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.black)

                // Count badge
                let likeCount = ShadowAccountManager.shared.pendingLikesCount
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(MatchaTokens.Colors.danger, in: Circle())
                        .offset(x: 24, y: -24)
                }
            }

            Text("Likes")
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(width: 76)
    }

    private func matchStoryCard(_ profile: UserProfile, chat: ChatPreview?) -> some View {
        let timerProgress = matchTimerProgress(chat: chat)

        return VStack(spacing: 8) {
            ZStack {
                // Background ring (dim)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 72, height: 72)

                // Timer ring — decreases as 24h runs out
                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(
                        timerProgress > 0.25
                            ? MatchaTokens.Colors.accent
                            : MatchaTokens.Colors.danger,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerProgress)

                // Avatar
                Group {
                    if let url = profile.photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .empty:
                                ZStack {
                                    storyAvatarPlaceholder(profile)
                                    ProgressView().tint(.white.opacity(0.5)).scaleEffect(0.7)
                                }
                            default:
                                storyAvatarPlaceholder(profile)
                            }
                        }
                    } else {
                        storyAvatarPlaceholder(profile)
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            }

            Text(profile.name.components(separatedBy: " ").first ?? profile.name)
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 76)
    }

    /// Returns 0.0…1.0 representing how much time is left (1.0 = full, 0.0 = expired)
    /// Uses `matchExpiresAt` from backend when available, falls back to createdAt + 24h
    private func matchTimerProgress(chat: ChatPreview?) -> CGFloat {
        let totalDuration: TimeInterval = 24 * 60 * 60 // 24h total
        guard let chat else { return 1.0 }

        let deadline: Date
        if let expiresAt = chat.matchExpiresAt {
            // Use backend expires_at
            deadline = expiresAt
        } else if let createdAt = chat.createdAt {
            // Fallback: created + 24h
            deadline = createdAt.addingTimeInterval(totalDuration)
        } else {
            return 1.0
        }

        let remaining = deadline.timeIntervalSinceNow
        guard remaining > 0 else { return 0 }
        return CGFloat(min(1.0, remaining / totalDuration))
    }

    private func matchedConversation(for profile: UserProfile) -> ChatPreview? {
        store.home.conversations.first { $0.partner.id == profile.id }
    }

    private func storyAvatarPlaceholder(_ profile: UserProfile) -> some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredConversations) { chat in
                NavigationLink(value: chat) {
                    conversationRow(chat)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(chat.partner.name), \(chat.lastMessage)\(chat.unreadCount > 0 ? ", \(chat.unreadCount) unread" : "")")
                .accessibilityHint("Open conversation with \(chat.partner.name)")
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Unmatch — red
                    Button(role: .destructive) {
                        unmatchTarget = chat
                        showUnmatchConfirm = true
                    } label: {
                        Label("Unmatch", systemImage: "heart.slash.fill")
                    }
                    .tint(MatchaTokens.Colors.danger)

                    // Report — orange
                    Button {
                        reportTarget = chat
                        showReport = true
                    } label: {
                        Label("Report", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tint(MatchaTokens.Colors.warning)

                    // Did you meet? — green (only if there's a confirmed deal)
                    if chat.activeDealStatus == .confirmed {
                        Button {
                            checkInTarget = chat
                            Task { await store.checkIn(chat: chat) }
                        } label: {
                            Label("Did you meet?", systemImage: "checkmark.circle.fill")
                        }
                        .tint(MatchaTokens.Colors.success)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    // Mute/Unmute — left swipe
                    Button {
                        Task { await store.toggleMute(chat: chat) }
                    } label: {
                        Label(
                            chat.isMuted ? "Unmute" : "Mute",
                            systemImage: chat.isMuted ? "speaker.fill" : "speaker.slash.fill"
                        )
                    }
                    .tint(Color.white.opacity(0.3))
                }
            }
        }
    }

    private func conversationRow(_ chat: ChatPreview) -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let url = chat.partner.photoURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .empty:
                                ZStack {
                                    rowAvatarPlaceholder(chat.partner)
                                    ProgressView().tint(.white.opacity(0.5))
                                }
                            default:
                                rowAvatarPlaceholder(chat.partner)
                            }
                        }
                    } else {
                        rowAvatarPlaceholder(chat.partner)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                if chat.partner.hasBlueCheck {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(MatchaTokens.Colors.baliBlue)
                        .background(Circle().fill(MatchaTokens.Colors.background).frame(width: 16, height: 16))
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.partner.name)
                        .font(.body.weight(chat.unreadCount > 0 ? .bold : .regular))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    if chat.isMuted {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
                    }

                    Spacer()

                    Text(chat.timestampText)
                        .font(.caption)
                        .foregroundStyle(
                            chat.unreadCount > 0
                                ? MatchaTokens.Colors.accent
                                : MatchaTokens.Colors.textSecondary.opacity(0.5)
                        )
                }

                HStack(spacing: 6) {
                    Text(chat.dealSummary?.detail ?? chat.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(
                            chat.unreadCount > 0
                                ? MatchaTokens.Colors.textPrimary
                                : MatchaTokens.Colors.textSecondary.opacity(0.7)
                        )
                        .lineLimit(1)

                    Spacer()

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(MatchaTokens.Colors.accent, in: Circle())
                    }
                }

                // Deal pipeline indicator
                if let dealSummary = chat.dealSummary {
                    dealPipelineRow(summary: dealSummary)
                }
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        // Subtle divider
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 82)
        }
    }

    // MARK: - Deal Pipeline Indicator

    private func dealPipelineRow(summary: ChatDealSummary) -> some View {
        let stage = dealStageIndex(summary.status)
        let stageColor = dealStageColor(summary.status)
        let stageIcon = dealStageIcon(summary.status)

        return HStack(spacing: 8) {
            // Status icon + label
            HStack(spacing: 5) {
                Image(systemName: stageIcon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(stageColor)
                Text(summary.status.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(stageColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stageColor.opacity(0.12), in: Capsule())

            // Pipeline progress bar
            HStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(i <= stage ? stageColor : Color.white.opacity(0.12))
                        .frame(height: 3)
                }
            }
            .frame(maxWidth: 60)

            Spacer()

            // CTA button
            if let cta = summary.cta {
                Text(cta.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MatchaTokens.Colors.accent, in: Capsule())
            }
        }
    }

    private func dealStageIndex(_ status: DealStatus) -> Int {
        switch status {
        case .draft:     0
        case .confirmed: 1
        case .visited:   2
        case .reviewed:  3
        default:         0
        }
    }

    private func dealStageColor(_ status: DealStatus) -> Color {
        switch status {
        case .draft:     MatchaTokens.Colors.warning
        case .confirmed: MatchaTokens.Colors.success
        case .visited:   MatchaTokens.Colors.accent
        case .reviewed:  MatchaTokens.Colors.accent
        case .noShow:    MatchaTokens.Colors.danger
        case .cancelled: MatchaTokens.Colors.danger
        }
    }

    private func dealStageIcon(_ status: DealStatus) -> String {
        switch status {
        case .draft:     "pencil.circle.fill"
        case .confirmed: "checkmark.seal.fill"
        case .visited:   "mappin.circle.fill"
        case .reviewed:  "star.circle.fill"
        case .noShow:    "person.fill.xmark"
        case .cancelled: "xmark.circle.fill"
        }
    }

    private func rowAvatarPlaceholder(_ profile: UserProfile) -> some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.elevated, MatchaTokens.Colors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    // MARK: - Empty State

    private var emptyChatsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.25))

            Text("No conversations yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Text("Match with creators or businesses\nto start a conversation")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Navigation Destination Enum

/// Typed navigation destinations specific to the Chats tab that are not
/// covered by the shared `UserProfile` and `ChatPreview` types.
enum ChatsNavDestination: Hashable {
    case likes([UserProfile])
}

// LikesListView is defined in MatchFeed/LikesListView.swift

// MARK: - Store

@MainActor
@Observable
final class ChatsStore {
    private let repository: any MatchaRepository

    var home = ChatHome(newMatches: [], conversations: [])
    var error: NetworkError?
    var hasLoaded = false

    init(repository: any MatchaRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        error = nil
        hasLoaded = true
        do {
            home = try await repository.fetchChatHome()
            print("[MATCHA] Chats loaded: \(home.conversations.count) conversations, \(home.newMatches.count) matches")
        } catch let networkError as NetworkError {
            print("[MATCHA] Chats error: \(networkError)")
            self.error = networkError
            home = ChatHome(newMatches: [], conversations: [])
        } catch {
            print("[MATCHA] Chats error: \(error)")
            self.error = .networkError(error)
            home = ChatHome(newMatches: [], conversations: [])
        }
    }

    /// Toggle muted state on a conversation with optimistic update + API call.
    func toggleMute(chat: ChatPreview) async {
        // Optimistic update
        let wasMuted = chat.isMuted
        let updatedConversations = home.conversations.map { c in
            guard c.id == chat.id else { return c }
            return ChatPreview(
                id: c.id, chatID: c.chatID, partner: c.partner,
                lastMessage: c.lastMessage, timestampText: c.timestampText,
                unreadCount: c.unreadCount, translationNote: c.translationNote,
                isMuted: !wasMuted,
                activeDealStatus: c.activeDealStatus, dealSummary: c.dealSummary,
                matchId: c.matchId, matchSource: c.matchSource,
                firstMessageByUserId: c.firstMessageByUserId,
                createdAt: c.createdAt, isAwaitingFirstMessage: c.isAwaitingFirstMessage
            )
        }
        home = ChatHome(newMatches: home.newMatches, conversations: updatedConversations)

        do {
            if wasMuted {
                try await repository.unmuteChat(chatId: chat.chatID)
            } else {
                try await repository.muteChat(chatId: chat.chatID)
            }
        } catch {
            // Revert on error
            await load()
        }
    }

    /// Check-in for a deal from the chat list swipe action.
    func checkIn(chat: ChatPreview) async {
        guard let dealSummary = chat.dealSummary else { return }
        do {
            _ = try await repository.checkInDeal(dealId: dealSummary.dealID)
            await load() // Reload to get updated deal status
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .networkError(error)
        }
    }

    /// Remove a conversation with optimistic update + API call.
    func unmatch(chat: ChatPreview) async {
        let original = home
        let updated = home.conversations.filter { $0.id != chat.id }
        home = ChatHome(newMatches: home.newMatches, conversations: updated)

        do {
            try await repository.unmatchChat(chatId: chat.chatID)
        } catch let networkError as NetworkError {
            self.error = networkError
            home = original // Revert
        } catch {
            self.error = .networkError(error)
            home = original
        }
    }
}

#Preview {
    NavigationStack {
        ChatsView(repository: MockMatchaRepository())
    }
    .preferredColorScheme(.dark)
}
