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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.large) {
                // Title — unified style across all tabs
                Text("Likes")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                if let error = store.error, store.likes.isEmpty {
                    errorBanner(error)
                }

                introCard

                if store.likes.isEmpty {
                    emptyState
                } else if shouldBlurLikes {
                    blurredLikesList
                } else {
                    LazyVStack(spacing: MatchaTokens.Spacing.medium) {
                        ForEach(store.likes) { profile in
                            likeCard(profile)
                        }
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                Text("People who liked you")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }

            Text("This screen is only for incoming interest. Browse profiles, like back, and keep everything simple.")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func likeCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                profileImage(profile)
                    .frame(width: 108, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(profile.name)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(MatchaTokens.Colors.textPrimary)
                            .lineLimit(1)

                        if profile.hasBlueCheck {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: 0x1DA1F2))
                        }
                    }

                    Text("\(profile.secondaryLine) · \(profile.district ?? "Bali")")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)

                    if let followers = profile.followersCount, followers > 0 {
                        Text("\(formatCount(followers)) followers")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }

                    if !profile.niches.isEmpty {
                        Text(profile.niches.prefix(2).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
            }

            HStack(spacing: 10) {
                Button {
                    selectedLikeProfile = profile
                } label: {
                    Text("View")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MatchaTokens.Colors.elevated, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    Task { await store.likeBack(profile: profile) }
                } label: {
                    let isMatched = store.matchedLikeIDs.contains(profile.id)
                    HStack(spacing: 6) {
                        Image(systemName: isMatched ? "heart.fill" : "heart")
                            .font(.caption.weight(.bold))
                        Text(isMatched ? "Matched" : "Like Back")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(isMatched ? .black : MatchaTokens.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        isMatched ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textPrimary,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .disabled(store.likeBackInFlightIDs.contains(profile.id) || store.matchedLikeIDs.contains(profile.id))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
