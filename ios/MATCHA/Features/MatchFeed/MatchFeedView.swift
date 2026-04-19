import Observation
import SwiftUI

// MARK: - MatchFeedView

struct MatchFeedView: View {
    @State private var store: MatchFeedStore
    private var shadowAccount: ShadowAccountManager { ShadowAccountManager.shared }
    private let repository: any MatchaRepository

    // Filter sheet
    @State private var showFilter = false

    // Navigate into chat after a match
    @State private var navigateToChat: ChatPreview? = nil

    // Profile detail sheet (tap on card)
    @State private var profileToShow: UserProfile? = nil

    // Undo pill — shown for 3-5s after a left swipe
    @State private var showUndoPill = false
    @State private var undoTask: Task<Void, Never>? {
        willSet { undoTask?.cancel() }
    }

    // Paywall
    @State private var showPaywall = false

    // Verification flow
    @State private var showVerification = false

    // Match celebration animation state
    @State private var celebrationAppeared = false

    // Bumble scroll position — id of currently-visible profile in the feed.
    @State private var scrollPositionID: UUID? = nil

    // Share sheet for post-match sharing
    @State private var showMatchShareSheet = false
    @State private var matchShareText = ""

    init(repository: any MatchaRepository) {
        self.repository = repository
        _store = State(initialValue: MatchFeedStore(repository: repository))
    }

    var body: some View {
        GeometryReader { geo in
            let topInset = max(geo.safeAreaInsets.top, 59) // Dynamic Island minimum

            ZStack {
                Color.black.ignoresSafeArea()

                if store.isLoading {
                    loadingState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.hasLoaded && store.currentProfile == nil {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    cardStackArea
                        .ignoresSafeArea(edges: .top)
                }

                // Top bar overlaid on card — aligned to the actual safe area.
                VStack {
                    topBar
                        .padding(.top, topInset + MatchaTokens.Spacing.small)
                    Spacer()
                }

                // Action buttons — on gradient, above system tab bar
                if !store.isLoading && store.currentProfile != nil {
                    VStack {
                        Spacer()
                        actionButtonsRow
                            .padding(.bottom, 12)
                    }
                }

                // Error toast
                if let error = store.error, store.profiles.isEmpty {
                    VStack {
                        errorBanner(error)
                        Spacer()
                    }
                    .padding(.top, topInset + MatchaTokens.Spacing.small)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: store.error != nil)
                }

                // Shadow account pending likes counter
                if shadowAccount.pendingLikesCount > 0
                    && !shadowAccount.isVerified {
                    VStack {
                        shadowPendingPill
                            .padding(.top, topInset + 52)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: shadowAccount.pendingLikesCount)
                }

                // Shadow blocked overlay
                if store.showShadowBlockedMessage {
                    shadowBlockedOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }

                // Undo pill -- top center, glass style
                if showUndoPill {
                    VStack {
                        undoPill
                            .padding(.top, topInset + 52)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Match celebration overlay
                if let matchProfile = store.matchCelebration {
                    matchCelebrationOverlay(matchProfile)
                        .transition(.opacity.animation(MatchaTokens.Animations.matchReveal))
                        .onAppear {
                            MatchaHaptic.success()
                            celebrationAppeared = false
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                celebrationAppeared = true
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        .onDisappear { celebrationAppeared = false }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .task {
            store.syncShadowState()
            await store.loadIfNeeded()
        }
        .onChange(of: shadowAccount.isVerified) { _, isVerified in
            guard isVerified else { return }
            store.syncShadowState()
        }
        // Filter sheet
        .sheet(isPresented: $showFilter) {
            FeedFilterView(filterState: Bindable(store).filterState) { _ in
                Task { await store.applyFilterChange() }
            }
        }
        // Profile detail sheet (tap on card)
        .sheet(item: $profileToShow) { profile in
            NavigationStack {
                ProfileDetailView(profile: profile)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // Paywall sheet
        .sheet(isPresented: $showPaywall) {
            PaywallView(.swipesExhausted)
        }
        // Post-match "Send Message" sheet
        .sheet(item: $navigateToChat) { chat in
            NavigationStack {
                ChatConversationView(chat: chat, repository: repository)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // Shadow account activation sheet (after 3rd shadow swipe)
        .sheet(isPresented: Binding(
            get: { store.showShadowActivationSheet },
            set: { store.showShadowActivationSheet = $0 }
        )) {
            shadowActivationSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        // Share sheet for post-match sharing
        .sheet(isPresented: $showMatchShareSheet) {
            ShareSheetView(activityItems: [matchShareText])
        }
        .sheet(isPresented: $showVerification) {
            NavigationStack {
                VerificationFlowView()
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        // Toast message overlay
        .overlay(alignment: .bottom) {
            if let message = store.toastMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: store.toastMessage)
            }
        }
    }

    // MARK: - Top Bar (stories row + filter)

    private var topBar: some View {
        HStack {
            Spacer()
            // Filter button only
            Button {
                showFilter = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(store.filterState.isActive ? MatchaTokens.Colors.accent : .white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.3), in: Circle())
            }
            .padding(.trailing, 16)
        }
    }

    private func storyAvatar(_ profile: UserProfile) -> some View {
        let isCurrent = store.currentProfile?.id == profile.id
        return Group {
            if let url = profile.photoURL {
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
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle().strokeBorder(
                isCurrent ? MatchaTokens.Colors.accent : .clear,
                lineWidth: 2
            )
        )
        .scaleEffect(isCurrent ? 1.1 : 0.9)
        .opacity(isCurrent ? 1.0 : 0.5)
        .animation(.spring(response: 0.3), value: store.currentIndex)
    }

    // MARK: - Card Stack Area — Bumble-style vertical paging scroll

    @ViewBuilder
    private var cardStackArea: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width
            let cardHeight = geo.size.height

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(store.filteredProfiles) { profile in
                        BumbleProfileCard(
                            profile: profile,
                            cardSize: CGSize(width: cardWidth, height: cardHeight)
                        )
                        .id(profile.id)
                        .frame(width: cardWidth, height: cardHeight)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $scrollPositionID, anchor: .top)
            .onChange(of: scrollPositionID) { _, newID in
                guard let newID,
                      let idx = store.filteredProfiles.firstIndex(where: { $0.id == newID }) else { return }
                if store.currentIndex != idx {
                    store.currentIndex = idx
                }
            }
            .onChange(of: store.currentIndex) { _, newIdx in
                let list = store.filteredProfiles
                guard newIdx >= 0, newIdx < list.count else { return }
                let targetID = list[newIdx].id
                if scrollPositionID != targetID {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        scrollPositionID = targetID
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 24) {
            // Skip (X) — 52pt glass circle
            actionButton(
                icon: "xmark",
                size: 52,
                bg: .clear,
                fg: MatchaTokens.Colors.danger
            ) {
                MatchaHaptic.light()
                store.skip()
                triggerUndoWindow()
            }
            .accessibilityLabel("Skip this profile")

            // Super swipe (bolt) — 48pt glass circle
            actionButton(
                icon: "bolt.fill",
                size: 48,
                bg: .clear,
                fg: MatchaTokens.Colors.warning
            ) {
                MatchaHaptic.heavy()
                store.superSwipe()
            }
            .accessibilityLabel("Super like this profile")

            // Like (heart) — 56pt accent green filled circle
            actionButton(
                icon: "heart.fill",
                size: 56,
                bg: MatchaTokens.Colors.accent,
                fg: .white
            ) {
                MatchaHaptic.medium()
                store.interested()
            }
            .accessibilityLabel("Like this profile")
        }
    }

    // MARK: - Undo Pill

    private var undoPill: some View {
        Button(action: undoLastSkip) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .semibold))
                Text("Undo")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Undo last skip")
    }

    private func triggerUndoWindow() {
        withAnimation(MatchaTokens.Animations.cardAppear) {
            showUndoPill = true
        }
        undoTask?.cancel()
        undoTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                showUndoPill = false
            }
        }
    }

    private func undoLastSkip() {
        undoTask?.cancel()
        withAnimation(.easeOut(duration: 0.3)) {
            showUndoPill = false
        }
        store.undoSkip()
    }

    private func actionButton(
        icon: String,
        size: CGFloat,
        bg: Color,
        fg: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(fg)
                .frame(width: size, height: size)
                .background {
                    if bg != .clear {
                        // Accent button (like) — solid green
                        Circle().fill(bg)
                    } else {
                        // Glass button — visible frosted circle
                        Circle()
                            .fill(.regularMaterial)
                            .overlay {
                                Circle()
                                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                            }
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty / Loading States

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProfileCardSkeleton()
                .padding(.horizontal, MatchaTokens.Spacing.large)

            Text("Brewing your feed…")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.3))
            Text("You've finished your cup")
                .font(.title3.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Text("Come back tomorrow for new Bali profiles\nor broaden your filters")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                    Text("Upgrade for unlimited swipes")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(MatchaTokens.Colors.accent, in: Capsule())
                .matchaShadow(MatchaTokens.Shadow.level1)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.subheadline)
            Text(error.errorDescription ?? "Something went wrong")
                .font(.subheadline)
            Spacer()
            Button("Retry") { Task { await store.loadFeed() } }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.accent)
                .accessibilityLabel("Retry loading feed")
                .accessibilityHint("Try loading the match feed again")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Shadow Account UI

    private var shadowPendingPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("\(shadowAccount.pendingLikesCount) likes pending")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
    }

    private var shadowBlockedOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(MatchaTokens.Colors.accent)

                VStack(spacing: 10) {
                    Text("You've saved 20 likes")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("That's the max! Complete verification\nto deliver them all.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    Button {
                        store.showShadowBlockedMessage = false
                        Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            showVerification = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Complete Verification")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                    }

                    Button {
                        withAnimation { store.showShadowBlockedMessage = false }
                    } label: {
                        Text("Dismiss")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(24)
        }
    }

    private var shadowActivationSheet: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 8)

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(MatchaTokens.Colors.accent)

            VStack(spacing: 10) {
                Text(
                    shadowAccount.isVerified
                        ? "Your \(shadowAccount.pendingLikesCount) likes are being delivered"
                        : "Your \(shadowAccount.pendingLikesCount) likes are waiting"
                )
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(
                    shadowAccount.isVerified
                        ? "You're verified now. MATCHA is delivering your saved likes."
                        : "Complete your profile to activate them.\nThey'll be delivered once you're verified."
                )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    store.showShadowActivationSheet = false
                    // Delay to let sheet dismiss before showing next one
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        showVerification = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Complete Profile")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                }

                Button {
                    store.showShadowActivationSheet = false
                } label: {
                    Text("Keep Browsing")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    // MARK: - Match Celebration (Full-Screen)

    private func matchCelebrationOverlay(_ profile: UserProfile) -> some View {
        ZStack {
            // Blurred dark background
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(Color.black.opacity(0.7))
                .ignoresSafeArea()

            // Particle burst — centered
            MatchCelebrationParticles(particleCount: 28)
                .frame(width: 300, height: 300)
                .offset(y: -40)

            VStack(spacing: 36) {
                Spacer()

                // Two profile photos flying in from edges and colliding center
                ZStack {
                    // My photo — flies in from left
                    celebrationAvatar(
                        photoURL: nil, // current user placeholder
                        fallbackIcon: "person.fill",
                        borderColor: MatchaTokens.Colors.accent.opacity(0.6)
                    )
                    .offset(x: celebrationAppeared ? -32 : -300)
                    .scaleEffect(celebrationAppeared ? 1.0 : 0.5)

                    // Partner photo — flies in from right
                    celebrationAvatar(
                        photoURL: profile.photoURL,
                        fallbackIcon: profile.heroSymbol,
                        borderColor: MatchaTokens.Colors.accent
                    )
                    .offset(x: celebrationAppeared ? 32 : 300)
                    .scaleEffect(celebrationAppeared ? 1.0 : 0.5)
                }
                .frame(height: 120)

                // Title text
                VStack(spacing: 12) {
                    Text("Fresh Match! \u{2615}")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .scaleEffect(celebrationAppeared ? 1.0 : 0.3)
                        .opacity(celebrationAppeared ? 1.0 : 0)

                    Text("You and **\(profile.name)** want to collaborate")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(celebrationAppeared ? 1.0 : 0)
                }

                Spacer()

                // CTA buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            do {
                                navigateToChat = try await store.resolveChatPreview(for: profile)
                                store.dismissMatch()
                            } catch let networkError as NetworkError {
                                store.error = networkError
                            } catch {
                                store.error = .networkError(error)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Send Message")
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                    }
                    .accessibilityLabel("Send message to \(profile.name)")
                    .opacity(celebrationAppeared ? 1.0 : 0)
                    .offset(y: celebrationAppeared ? 0 : 30)

                    Button {
                        store.dismissMatch()
                    } label: {
                        Text("Keep Swiping")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                    }
                    .accessibilityLabel("Keep swiping")
                    .accessibilityHint("Dismiss match celebration and continue browsing")
                    .opacity(celebrationAppeared ? 1.0 : 0)
                    .offset(y: celebrationAppeared ? 0 : 20)

                    // Share your match
                    Button {
                        let referralCode = NetworkService.shared.currentUserID ?? "matcha"
                        matchShareText = "Just matched with \(profile.name) on MATCHA! \u{1F375} Join me: https://matcha.app/invite/\(referralCode)"
                        showMatchShareSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Share Your Match")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .accessibilityLabel("Share your match with \(profile.name)")
                    .opacity(celebrationAppeared ? 1.0 : 0)
                    .offset(y: celebrationAppeared ? 0 : 15)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .padding(24)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: celebrationAppeared)
    }

    private func celebrationAvatar(
        photoURL: URL?,
        fallbackIcon: String,
        borderColor: Color
    ) -> some View {
        Group {
            if let url = photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    default:
                        celebrationAvatarPlaceholder(icon: fallbackIcon)
                    }
                }
            } else {
                celebrationAvatarPlaceholder(icon: fallbackIcon)
            }
        }
        .frame(width: 108, height: 108)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(borderColor, lineWidth: 3))
        .overlay(Circle().strokeBorder(Color.black.opacity(0.4), lineWidth: 4))
        .shadow(color: MatchaTokens.Colors.accent.opacity(0.3), radius: 12, y: 0)
    }

    private func celebrationAvatarPlaceholder(icon: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.elevated, MatchaTokens.Colors.heroGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.4))
        }
    }
}

// MARK: - ScrollViewOffsetPreferenceKey

private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - BumbleProfileCard
//
// Pure Bumble-style card: full-screen vertical scroll inside the card.
// Users vertical-scroll через фото/био/ниши/ещё фото, а outer ScrollView
// (в MatchFeedView.cardStackArea) снапит между профилями по страницам.
// Никаких horizontal swipe gestures — Pass/Like делают кнопки в actionButtonsRow.

private struct BumbleProfileCard: View {
    let profile: UserProfile
    let cardSize: CGSize

    @State private var currentPhotoIndex: Int = 0

    private var photoURLList: [URL] {
        if !profile.photoURLs.isEmpty { return profile.photoURLs }
        if let url = profile.photoURL { return [url] }
        return []
    }

    @ViewBuilder
    private var verificationBadgePill: some View {
        switch profile.verificationLevel {
        case .blueCheck:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 9, weight: .bold))
                Text("BLUE CHECK").font(.system(size: 10, weight: .bold)).tracking(0.5)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(MatchaTokens.Colors.accent, in: Capsule())
        case .verified:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.shield.fill").font(.system(size: 9, weight: .bold))
                Text("VERIFIED").font(.system(size: 10, weight: .bold)).tracking(0.5)
            }
            .foregroundStyle(MatchaTokens.Colors.baliBlue)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(MatchaTokens.Colors.baliBlue.opacity(0.2), in: Capsule())
        case .shadow:
            EmptyView()
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero photo — takes ~60% of screen
                ZStack(alignment: .bottom) {
                    heroPhoto
                        .frame(width: cardSize.width, height: cardSize.height * 0.6)
                        .clipped()

                    if photoURLList.count > 1 {
                        HStack(spacing: 0) {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentPhotoIndex = max(0, currentPhotoIndex - 1)
                                    }
                                }
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        currentPhotoIndex = min(photoURLList.count - 1, currentPhotoIndex + 1)
                                    }
                                }
                        }
                    }

                    // Gradient for readability
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.7), location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)

                    // Name + info overlay (спека §3.4: имя, роль, район, рейтинг, бейджи)
                    VStack(alignment: .leading, spacing: 6) {
                        // Верификационная плашка (VERIFIED / BLUE CHECK)
                        verificationBadgePill
                        // Имя + чекмарк
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(profile.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            if profile.verificationLevel.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(MatchaTokens.Colors.accent)
                                    .font(.system(size: 18))
                            }
                        }
                        Text(profile.secondaryLine)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.85))
                        // Район + рейтинг + collabs одной строкой
                        HStack(spacing: 12) {
                            if let district = profile.district {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 11))
                                    Text(district)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                            if let rating = profile.rating, rating > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(MatchaTokens.Colors.warning)
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            if profile.completedCollabsCount > 0 {
                                HStack(spacing: 3) {
                                    Image(systemName: "handshake.fill")
                                        .font(.system(size: 11))
                                    Text("\(profile.completedCollabsCount) collabs")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Bio
                if !profile.bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(profile.bio)
                            .font(.system(size: 15))
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                }

                // Niches
                if !profile.niches.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Niches")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        WrappingNicheTags(niches: profile.niches)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }

                // Additional photos interleaved with info
                ForEach(Array(photoURLList.enumerated().dropFirst()), id: \.offset) { _, url in
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            Color.black
                        }
                    }
                    .frame(width: cardSize.width, height: cardSize.height * 0.55)
                    .clipped()
                    .padding(.top, 16)
                }

                // Bottom padding so last content isn't flush with action bar
                Color.clear.frame(height: 120)
            }
        }
        .background(Color.black)
    }

    @ViewBuilder
    private var heroPhoto: some View {
        if let url = photoURLList[safe: currentPhotoIndex] {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.black
                }
            }
        } else {
            Color(white: 0.08)
        }
    }
}

// MARK: - SwipeCard

private struct SwipeCard: View {
    let profile: UserProfile
    let cardSize: CGSize
    let stackScale: CGFloat
    let stackYOffset: CGFloat
    let isTopCard: Bool
    @Binding var programmaticSwipe: SwipeDirection?
    let onSwipeCompleted: (SwipeDirection) -> Void
    var onTap: (() -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var currentPhotoIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 80
    private let rotationFactor: CGFloat = 20

    /// Horizontal swipe is only allowed when the scroll is at the top
    private var isSwipeEnabled: Bool {
        scrollOffset >= -1 // small tolerance for floating-point
    }

    private var rotation: Angle {
        .degrees(Double(dragOffset.width / rotationFactor))
    }

    private var likeOpacity: Double {
        max(0, min(1, Double(dragOffset.width - 40) / 60))
    }

    private var nopeOpacity: Double {
        max(0, min(1, Double(-dragOffset.width - 40) / 60))
    }

    var body: some View {
        ZStack {
            cardContent
                .overlay(swipeLabels)
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .scaleEffect(isTopCard && isDragging ? 0.97 : stackScale)
        .offset(y: isTopCard ? 0 : stackYOffset)
        .rotationEffect(isTopCard ? rotation : .zero)
        .offset(x: isTopCard ? dragOffset.width : 0,
                y: 0) // No vertical movement during swipe
        .animation(isDragging ? nil : MatchaTokens.Animations.cardAppear, value: stackScale)
        .gesture(isTopCard && isSwipeEnabled ? dragGesture : nil)
        .onChange(of: programmaticSwipe) { _, newValue in
            guard isTopCard, let direction = newValue else { return }
            triggerProgrammaticSwipe(direction)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.name), \(profile.secondaryLine), \(profile.district ?? "Bali")")
        .accessibilityAction(named: "Like") {
            onSwipeCompleted(.right)
        }
        .accessibilityAction(named: "Skip") {
            onSwipeCompleted(.left)
        }
    }

    // MARK: - Card Content

    private var photoURLList: [URL] {
        if !profile.photoURLs.isEmpty { return profile.photoURLs }
        if let url = profile.photoURL { return [url] }
        return []
    }

    private var cardContent: some View {
        ZStack(alignment: .top) {
            // Opaque background so cards behind don't bleed through on scroll
            Color.black.ignoresSafeArea()

            // Scrollable card content (Bumble-style vertical reveal)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Scroll offset tracker
                    GeometryReader { innerGeo in
                        Color.clear
                            .preference(
                                key: ScrollViewOffsetPreferenceKey.self,
                                value: innerGeo.frame(in: .named("cardScroll")).minY
                            )
                    }
                    .frame(height: 0)

                    // Hero photo section — ~70% of card height
                    ZStack(alignment: .bottom) {
                        cardPhoto
                            .frame(width: cardSize.width, height: cardSize.height * 0.7)
                            .clipped()

                        // Tap zones for photo navigation (left/right halves) or single-photo tap
                        if photoURLList.count > 1 {
                            HStack(spacing: 0) {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            currentPhotoIndex = max(0, currentPhotoIndex - 1)
                                        }
                                    }
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            currentPhotoIndex = min(photoURLList.count - 1, currentPhotoIndex + 1)
                                        }
                                    }
                            }
                        } else {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if isTopCard { onTap?() }
                                }
                        }

                        // Bottom gradient on the hero photo
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .clear, location: 0.35),
                                .init(color: .black.opacity(0.3), location: 0.6),
                                .init(color: .black.opacity(0.75), location: 0.85),
                                .init(color: .black.opacity(0.95), location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .allowsHitTesting(false)

                        // Name + role overlay on bottom of hero photo
                        VStack(alignment: .leading, spacing: 4) {
                            profileInfoOverlay
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: cardSize.height * 0.7)

                    // Scrollable info section (revealed by scrolling down)
                    scrollableInfoSection
                }
            }
            .coordinateSpace(name: "cardScroll")
            .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .scrollDisabled(!isTopCard)

            // Page indicator — segmented bars, offset so they don't overlap filter icon
            if photoURLList.count > 1 {
                VStack {
                    HStack(spacing: 4) {
                        ForEach(0..<photoURLList.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPhotoIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(height: 3)
                                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                                .animation(.easeInOut(duration: 0.2), value: currentPhotoIndex)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 68) // clears the filter icon (36pt + 16pt + margin)
                    .padding(.top, 72)

                    Spacer()
                }
                .allowsHitTesting(false)
            }

            // Scroll hint at bottom of visible area (when at top)
            if scrollOffset >= -1 {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                        Text("Scroll for more")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 80) // above action buttons
                }
            }
        }
    }

    // MARK: - Scrollable Info Section

    private var scrollableInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Bio
            if !profile.bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Stats row
            scrollableStatsRow

            // Niche tags
            if !profile.niches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Niches")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                    WrappingNicheTags(niches: profile.niches)
                }
            }

            // Details section
            scrollableDetailsSection

            // Bottom spacer so content doesn't hide behind action buttons
            Spacer()
                .frame(height: 100)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black)
    }

    // MARK: - Scrollable Stats Row

    private var scrollableStatsRow: some View {
        HStack(spacing: 0) {
            if let followers = profile.followersCount, followers > 0 {
                statItem(value: formatFollowers(followers), label: "Followers")
            }
            if let rating = profile.rating {
                statItem(value: String(format: "%.1f", rating), label: "Rating", icon: "star.fill", iconColor: .yellow)
            }
            if profile.completedCollabsCount > 0 {
                statItem(value: "\(profile.completedCollabsCount)", label: "Collabs")
            }
            if profile.verifiedVisits > 0 {
                statItem(value: "\(profile.verifiedVisits)", label: "Verified", icon: "checkmark.circle.fill", iconColor: MatchaTokens.Colors.success)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func statItem(value: String, label: String, icon: String? = nil, iconColor: Color = .white) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(iconColor)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scrollable Details Section

    private var scrollableDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let location = profile.district ?? profile.locationDistrict {
                detailRow(icon: "mappin.circle.fill", label: "Location", value: location)
            }
            if !profile.languages.isEmpty {
                detailRow(icon: "globe", label: "Languages", value: profile.languages.joined(separator: ", "))
            }
            detailRow(icon: "arrow.triangle.2.circlepath", label: "Collab Type", value: profile.collaborationType.title)
            if profile.hasBlueCheck {
                detailRow(icon: "checkmark.seal.fill", label: "Status", value: "Blue Check Verified", valueColor: Color(hex: 0x1DA1F2))
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String, valueColor: Color = .white.opacity(0.85)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(MatchaTokens.Colors.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(valueColor)
            }
        }
    }

    // MARK: - Photo

    @ViewBuilder
    private var cardPhoto: some View {
        let urls = photoURLList
        let photoHeight = cardSize.height * 0.7
        if !urls.isEmpty {
            let safeIndex = min(currentPhotoIndex, urls.count - 1)
            AsyncImage(url: urls[max(0, safeIndex)]) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: cardSize.width, height: photoHeight)
                        .clipped()
                        .id(safeIndex) // force view identity change for transition
                        .transition(.opacity)
                case .failure:
                    photoPlaceholder
                case .empty:
                    // Shimmer loading with warm gradient
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: 0x1A3A2A), Color(hex: 0x0F2B20), Color(hex: 0x162230)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        ProgressView()
                            .tint(MatchaTokens.Colors.accent.opacity(0.6))
                            .scaleEffect(1.2)
                    }
                    .frame(width: cardSize.width, height: photoHeight)
                @unknown default:
                    photoPlaceholder
                }
            }
        } else {
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            // Warm Bali-inspired gradient instead of dark/black
            LinearGradient(
                colors: [
                    Color(hex: 0x1A3A2A),  // deep forest green
                    Color(hex: 0x0F2B20),  // darker green
                    Color(hex: 0x162230),  // ocean blue tint
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle pattern overlay
            Circle()
                .fill(MatchaTokens.Colors.accent.opacity(0.04))
                .frame(width: 300, height: 300)
                .offset(x: -60, y: -80)
                .blur(radius: 60)

            Circle()
                .fill(Color(hex: 0x2A5A4A).opacity(0.15))
                .frame(width: 200, height: 200)
                .offset(x: 80, y: 100)
                .blur(radius: 40)

            VStack(spacing: 16) {
                Image(systemName: profile.heroSymbol)
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.3))

                Text(profile.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .frame(width: cardSize.width, height: cardSize.height * 0.7)
    }

    // MARK: - Profile Info Overlay

    private var profileInfoOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name + role
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(profile.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text(profile.secondaryLine)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.65)

            // Location + followers + rating — key metrics row
            HStack(spacing: 14) {
                if let location = profile.district ?? profile.locationDistrict {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(location)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                if let followers = profile.followersCount, followers > 0 {
                    Text(formatFollowers(followers))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }

                if let rating = profile.rating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                if profile.verifiedVisits > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MatchaTokens.Colors.success)
                        Text("\(profile.verifiedVisits)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }

            // Niche tags
            if !profile.niches.isEmpty {
                WrappingNicheTags(niches: Array(profile.niches.prefix(6)))
                    .padding(.top, 2)
            }

            // Has Offer badge
            if profile.hasActiveOffer {
                Text("Has Offer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MatchaTokens.Colors.accent, in: Capsule())
            }
        }
    }

    private func formatFollowers(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }

    // MARK: - Swipe Labels

    private var swipeLabels: some View {
        ZStack {
            // LIKE label — appears when dragging right
            VStack {
                HStack {
                    likeLabel
                        .opacity(likeOpacity)
                        .padding(.leading, 24)
                        .padding(.top, 48)
                    Spacer()
                }
                Spacer()
            }

            // NOPE label — appears when dragging left
            VStack {
                HStack {
                    Spacer()
                    nopeLabel
                        .opacity(nopeOpacity)
                        .padding(.trailing, 24)
                        .padding(.top, 48)
                }
                Spacer()
            }

            // SUPER label — appears during programmatic super swipe
            if programmaticSwipe == .super {
                superLabel
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var likeLabel: some View {
        Text("LIKE")
            .font(.system(size: 36, weight: .black))
            .foregroundStyle(MatchaTokens.Colors.success)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.success, lineWidth: 3)
            )
            .rotationEffect(.degrees(-15))
    }

    private var nopeLabel: some View {
        Text("NOPE")
            .font(.system(size: 36, weight: .black))
            .foregroundStyle(MatchaTokens.Colors.danger)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.danger, lineWidth: 3)
            )
            .rotationEffect(.degrees(15))
    }

    private var superLabel: some View {
        Text("SUPER")
            .font(.system(size: 42, weight: .black))
            .foregroundStyle(MatchaTokens.Colors.warning)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.warning, lineWidth: 3)
            )
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let dx = abs(value.translation.width)
                let dy = abs(value.translation.height)

                // Once dragging is started, keep tracking
                if isDragging {
                    dragOffset = CGSize(width: value.translation.width, height: value.translation.height * 0.12)
                    return
                }

                // Need enough movement to decide direction (avoid noise at start)
                guard dx + dy > 15 else { return }

                // If mostly horizontal → start swipe drag
                if dx > dy {
                    isDragging = true
                    dragOffset = CGSize(width: value.translation.width, height: value.translation.height * 0.12)
                }
                // If mostly vertical → don't interfere, let ScrollView handle
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false

                let xOffset = value.translation.width
                let velocity = value.velocity.width
                let exceedsThreshold = abs(xOffset) > swipeThreshold || abs(velocity) > 600

                if exceedsThreshold {
                    let direction: SwipeDirection = xOffset > 0 ? .right : .left
                    flyOffScreen(direction: direction)
                } else {
                    withAnimation(MatchaTokens.Animations.cardAppear) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Animation helpers

    private func flyOffScreen(direction: SwipeDirection) {
        let targetX: CGFloat = direction == .right ? 800 : -800
        withAnimation(.easeIn(duration: 0.3)) {
            dragOffset = CGSize(width: targetX, height: 0)
        }
        // Notify parent after card has flown off screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            onSwipeCompleted(direction)
            // Reset offset silently — card is already off screen and will be replaced
            dragOffset = .zero
            scrollOffset = 0
            currentPhotoIndex = 0
        }
    }

    private func triggerProgrammaticSwipe(_ direction: SwipeDirection) {
        // Small "wind-up" then fly off
        let windUp: CGFloat = direction == .right ? 20 : -20
        withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
            dragOffset = CGSize(width: windUp, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            flyOffScreen(direction: direction)
        }
    }

}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - WrappingNicheTags (FlowLayout for tags)

private struct WrappingNicheTags: View {
    let niches: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Simple 2-row approach: split tags
            let firstRow = Array(niches.prefix(3))
            let secondRow = niches.count > 3 ? Array(niches.suffix(from: 3)) : []

            HStack(spacing: 6) {
                ForEach(firstRow, id: \.self) { tagPill($0) }
            }
            if !secondRow.isEmpty {
                HStack(spacing: 6) {
                    ForEach(secondRow, id: \.self) { tagPill($0) }
                }
            }
        }
    }

    private func tagPill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    MatchFeedView(repository: MockMatchaRepository())
        .preferredColorScheme(.dark)
}
