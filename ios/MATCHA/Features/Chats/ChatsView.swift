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

    // Segments
    @State private var selectedSegment: ChatSegment = .all

    enum ChatSegment: String, CaseIterable {
        case all = "All"
        case chats = "Messages"
        case deals = "Deals"
    }

    init(repository: any MatchaRepository) {
        self.repository = repository
        _store = State(initialValue: ChatsStore(repository: repository))
    }

    // Filtered conversations per segment
    private var allConversations: [ChatPreview] {
        filteredConversations
    }

    private var chatOnlyConversations: [ChatPreview] {
        filteredConversations.filter { $0.dealSummary == nil }
    }

    private var dealConversations: [ChatPreview] {
        filteredConversations.filter { $0.dealSummary != nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("Messages")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Stories row
            newMatchesSection
                .padding(.bottom, 4)

            // Segment tabs BELOW stories
            HStack(spacing: 8) {
                ForEach(ChatSegment.allCases, id: \.self) { segment in
                    let isSelected = selectedSegment == segment
                    Button {
                        withAnimation(.spring(response: 0.25)) { selectedSegment = segment }
                    } label: {
                        Text(segment.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? .black : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                isSelected ? MatchaTokens.Colors.accent : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)

            List {
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
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                }

                switch selectedSegment {
                case .all:
                    if !allConversations.isEmpty {
                        segmentConversationsList(allConversations)
                    } else if store.hasLoaded {
                        emptyChatsState
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                case .chats:
                    if !chatOnlyConversations.isEmpty {
                        segmentConversationsList(chatOnlyConversations)
                    } else if store.hasLoaded {
                        emptySegmentState(icon: "bubble.left.and.bubble.right", text: "No messages yet", subtitle: "Conversations without deals will appear here")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                case .deals:
                    if !dealConversations.isEmpty {
                        let active = dealConversations.filter {
                            $0.activeDealStatus == .draft || $0.activeDealStatus == .confirmed
                        }
                        let completed = dealConversations.filter {
                            $0.activeDealStatus == .visited || $0.activeDealStatus == .reviewed
                        }

                        if !active.isEmpty {
                            Section {
                                segmentConversationsList(active)
                            } header: {
                                Text("Active Deals")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .textCase(nil)
                            }
                            .listRowBackground(Color.clear)
                        }
                        if !completed.isEmpty {
                            Section {
                                segmentConversationsList(completed)
                            } header: {
                                Text("Completed")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .textCase(nil)
                            }
                            .listRowBackground(Color.clear)
                        }
                    } else if store.hasLoaded {
                        emptySegmentState(icon: "person.2.circle", text: "No deals yet", subtitle: "Start a deal in any chat")
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .refreshable { await store.load() }
        .onAppear {
            guard store.hasLoaded else { return }
            Task { await store.load() }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationBarHidden(true)
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
    private var uncontactedMatches: [NewMatch] {
        store.home.newMatches.filter { match in
            guard let chat = matchedConversation(for: match.profile) else { return true }
            return chat.isAwaitingFirstMessage
        }
    }

    private var newMatchesSection: some View {
        TimelineView(.periodic(from: .now, by: 60)) { _ in
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("New Matches")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Text("Waiting for their first message")
                    .font(.system(size: 11))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
            }
            .padding(.horizontal, 24)

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
                    // Tap always opens chat (creates one if needed)
                    ForEach(uncontactedMatches) { match in
                        let chat = matchedConversation(for: match.profile) ?? ChatPreview(
                            partner: match.profile,
                            lastMessage: "",
                            timestampText: "",
                            unreadCount: 0,
                            matchId: match.matchId,
                            matchSource: "swipe",
                            isAwaitingFirstMessage: true,
                            matchExpiresAt: match.expiresAt
                        )
                        NavigationLink(value: chat) {
                            matchStoryCard(match)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("New match: \(match.profile.name)")
                        .accessibilityHint("Open chat with \(match.profile.name)")
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
            }
        }
        } // TimelineView
    }

    private var likesStoryCard: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [MatchaTokens.Colors.accent, MatchaTokens.Colors.accent.opacity(0.6)],
                            center: .init(x: 0.3, y: 0.25),
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 68, height: 68)

                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundStyle(.black)

                // Count badge — shows real incoming likes from API
                let likeCount = store.incomingLikesCount
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

    private func matchStoryCard(_ match: NewMatch) -> some View {
        let timerProgress = matchTimerProgress(match)
        let profile = match.profile

        return VStack(spacing: 8) {
            ZStack {
                // Background ring (dim)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                    .frame(width: 72, height: 72)

                // Timer ring — fills based on remaining 48h
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
            .padding(2) // prevent ring stroke clipping

            Text(profile.name.components(separatedBy: " ").first ?? profile.name)
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 76)
    }

    /// Returns 0.0…1.0 representing how much time is left (1.0 = full, 0.0 = expired)
    private func matchTimerProgress(_ match: NewMatch) -> CGFloat {
        let totalDuration: TimeInterval = 48 * 60 * 60 // 48h per spec

        let deadline: Date
        if let expiresAt = match.expiresAt {
            deadline = expiresAt
        } else if let createdAt = match.createdAt {
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
        segmentConversationsList(filteredConversations)
    }

    @ViewBuilder
    private func segmentConversationsList(_ chats: [ChatPreview]) -> some View {
        ForEach(chats) { chat in
            ZStack {
                NavigationLink(value: chat) { EmptyView() }
                    .opacity(0)
                conversationRow(chat)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityLabel("\(chat.partner.name), \(chat.lastMessage)")
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    unmatchTarget = chat
                    showUnmatchConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                .tint(MatchaTokens.Colors.danger)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                    Task { await store.toggleMute(chat: chat) }
                } label: {
                    Label(
                        chat.isMuted ? "Unmute" : "Mute",
                        systemImage: chat.isMuted ? "speaker.fill" : "speaker.slash.fill"
                    )
                }
                .tint(Color(hex: 0x5B7AFF))
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    private func emptySegmentState(icon: String, text: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.2))
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
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

                // Deal pipeline indicator (unified 24px style)
                if let dealSummary = chat.dealSummary {
                    DealPipelineMiniView(
                        status: dealSummary.status,
                        showCTA: dealSummary.cta != nil
                    )
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

            Text("Match with influencers or businesses\nto start a conversation")
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
    var incomingLikesCount: Int = 0

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
            // Fetch incoming likes count for badge
            let activity = try await repository.fetchActivitySummary()
            incomingLikesCount = activity.likes.count
            print("[MATCHA] Chats loaded: \(home.conversations.count) conversations, \(home.newMatches.count) matches, \(incomingLikesCount) likes")
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
