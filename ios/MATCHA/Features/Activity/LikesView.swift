import SwiftUI

struct LikesView: View {
    let currentUser: UserProfile

    @State private var store: DealsStore
    @State private var showLikesPaywall = false
    @State private var selectedLikeProfile: UserProfile?

    init(currentUser: UserProfile, repository: any MatchaRepository) {
        self.currentUser = currentUser
        _store = State(initialValue: DealsStore(repository: repository))
    }

    private var shouldBlurLikes: Bool {
        currentUser.role == .business && currentUser.subscriptionPlan == .free
    }

    /// Free план: первая карточка видна, остальные blurred (PRO).
    /// Pro / Black: все видны, Like Back работает.
    private var isPro: Bool {
        currentUser.subscriptionPlan != .free
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header: title + count pill
                HStack {
                    Text("Likes")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    if !store.likes.isEmpty {
                        Text("\(store.likes.count) new")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(MatchaTokens.Colors.accent.opacity(0.12), in: Capsule())
                            .overlay(Capsule().strokeBorder(MatchaTokens.Colors.accent.opacity(0.3), lineWidth: 0.5))
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 24)

                if let error = store.error, store.likes.isEmpty {
                    errorBanner(error)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                if store.likes.isEmpty {
                    emptyState
                        .padding(.top, 60)
                        .padding(.horizontal, 24)
                } else {
                    // Caption
                    Text("People who already liked you. Like back to match instantly.")
                        .font(.system(size: 13))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                    // 2-column grid — первая карточка видна, остальные blurred (для free)
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(Array(store.likes.enumerated()), id: \.element.id) { index, profile in
                            likeGridCard(profile: profile, index: index)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Upgrade card (только для free пользователей)
                    if !isPro && store.likes.count > 1 {
                        upgradeCard
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable { await store.load() }
        .onAppear {
            guard store.hasLoaded else { return }
            Task { await store.load() }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLikesPaywall) {
            PaywallView(.blurredLikes)
        }
        .sheet(item: $selectedLikeProfile) { profile in
            NavigationStack {
                ProfileDetailView(profile: profile)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task { await store.loadIfNeeded() }
    }

    // MARK: - Grid card (v3 design)

    @ViewBuilder
    private func likeGridCard(profile: UserProfile, index: Int) -> some View {
        // Free + index > 0 → blurred. Pro → all visible.
        let blurred = !isPro && index > 0

        Button {
            if blurred {
                showLikesPaywall = true
            } else {
                selectedLikeProfile = profile
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                // Photo / placeholder
                photoBackground(profile: profile)
                    .blur(radius: blurred ? 18 : 0)

                // Bottom gradient
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.5),
                        .init(color: .black.opacity(0.85), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Lock icon for blurred
                if blurred {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.6))
                                .frame(width: 38, height: 38)
                                .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                                .background(.ultraThinMaterial, in: Circle())
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                        }
                        Text("PRO")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Bottom info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(blurred ? "••••" : profile.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if !blurred && profile.verificationLevel == .blueCheck {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(MatchaTokens.Colors.baliBlue)
                        }
                    }
                    Text(blurred ? "••• ago" : (profile.district ?? "Bali"))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .aspectRatio(3.0/4.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func photoBackground(profile: UserProfile) -> some View {
        if let url = profile.photoURLs.first ?? profile.photoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    photoPlaceholder(profile: profile)
                }
            }
        } else {
            photoPlaceholder(profile: profile)
        }
    }

    private func photoPlaceholder(profile: UserProfile) -> some View {
        // Цветной gradient placeholder с инициалом, как в v3 design
        let hue = Double(abs(profile.name.hashValue) % 360) / 360.0
        return ZStack {
            LinearGradient(
                colors: [
                    Color(hue: hue, saturation: 0.5, brightness: 0.35),
                    Color(hue: (hue + 0.1).truncatingRemainder(dividingBy: 1), saturation: 0.4, brightness: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Soft radial highlight (как в дизайне v3)
            RadialGradient(
                colors: [.white.opacity(0.18), .clear],
                center: UnitPoint(x: 0.3, y: 0.3),
                startRadius: 0,
                endRadius: 120
            )
        }
    }

    // MARK: - Upgrade card

    private var upgradeCard: some View {
        Button { showLikesPaywall = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text("See everyone who liked you")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("Upgrade to MATCHA Pro to skip the queue and match with the people already in your corner.")
                    .font(.system(size: 13))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Try MATCHA Pro")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [MatchaTokens.Colors.surface, MatchaTokens.Colors.elevated],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.accent.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ error: NetworkError) -> some View {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var introCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            Text("People who liked you")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.accent.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func likeCard(_ profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            // Avatar — tap opens profile
            Button { selectedLikeProfile = profile } label: {
                profileImage(profile)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(1)

                    if profile.hasBlueCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: 0x1DA1F2))
                    }
                }

                Text("\(profile.secondaryLine) · \(profile.district ?? "Bali")")
                    .font(.system(size: 13))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .lineLimit(1)

                if let followers = profile.followersCount, followers > 0 {
                    Text("\(formatCount(followers)) followers")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }

            Spacer()

            // Like Back button
            // - Blogger free: видит лайки unblurred но tap → paywall
            // - Business free: видит blurred + paywall при tap
            // - Любой Pro/Black: tap работает сразу → match
            Button {
                if currentUser.subscriptionPlan == .free {
                    showLikesPaywall = true
                } else {
                    Task { await store.likeBack(profile: profile) }
                }
            } label: {
                let isMatched = store.matchedLikeIDs.contains(profile.id)
                HStack(spacing: 4) {
                    Image(systemName: isMatched ? "heart.fill" : "heart")
                        .font(.system(size: 12, weight: .bold))
                    Text(isMatched ? "Matched" : "Like Back")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(isMatched ? .black : MatchaTokens.Colors.background)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isMatched ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textPrimary,
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(store.likeBackInFlightIDs.contains(profile.id) || store.matchedLikeIDs.contains(profile.id))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.outline.opacity(0.7), lineWidth: 1)
        )
    }

    private var blurredLikesList: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            ForEach(Array(store.likes.prefix(3))) { profile in
                blurredLikeCard(profile)
            }

            Button {
                showLikesPaywall = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.bold))
                    Text("Unlock Likes")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func blurredLikeCard(_ profile: UserProfile) -> some View {
        HStack(alignment: .top, spacing: 14) {
            profileImage(profile)
                .frame(width: 108, height: 132)
                .blur(radius: 10)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 110, height: 14)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 12)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 90, height: 10)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.bold))
                    Text("Upgrade to reveal")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(MatchaTokens.Colors.accent)
            }
            .blur(radius: 5)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.25))
            Text("No likes yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Text("Likes will land here as a clean vertical queue.")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func profileImage(_ profile: UserProfile) -> some View {
        if let url = profile.photoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    avatarPlaceholder(profile)
                }
            }
        } else {
            avatarPlaceholder(profile)
        }
    }

    private func avatarPlaceholder(_ profile: UserProfile) -> some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

#Preview {
    NavigationStack {
        LikesView(
            currentUser: MockSeedData.makeCurrentUser(role: .blogger, name: "Nadia"),
            repository: MockMatchaRepository()
        )
    }
    .preferredColorScheme(.dark)
}
