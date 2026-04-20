import SwiftUI

// MARK: - LikesListView

/// Shows profiles that have liked the current user.
/// Opened as a sheet from the pending likes pill in MatchFeedView.
struct LikesListView: View {
    let profiles: [UserProfile]
    var repository: (any MatchaRepository)? = nil
    /// Передаётся из ChatsView чтобы решить показывать paywall или делать match.
    var currentUser: UserProfile? = nil
    @State private var matchedBack: Set<UUID> = []
    @State private var inFlightIDs: Set<UUID> = []
    @State private var errorMessage: String?
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if profiles.isEmpty {
                        emptyState
                    } else {
                        ForEach(profiles) { profile in
                            likeRow(profile)
                        }
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.vertical, MatchaTokens.Spacing.medium)
                .padding(.bottom, 40)
            }
            .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
            .navigationTitle("Likes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(.blurredLikes)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.3))
            Text("No likes yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Text("Profiles that like you will appear here")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Like Row

    private func likeRow(_ profile: UserProfile) -> some View {
        HStack(spacing: 14) {
            // Avatar
            Group {
                if let url = profile.photoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            avatarPlaceholder(profile)
                        }
                    }
                } else {
                    avatarPlaceholder(profile)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(MatchaTokens.Colors.accent.opacity(0.4), lineWidth: 2))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    if profile.hasBlueCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: 0x1DA1F2))
                    }
                }
                Text("\(profile.secondaryLine) · \(profile.district ?? "Bali")")
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)

                if let followers = profile.followersCount, followers > 0 {
                    Text("\(formatCount(followers)) followers")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }

            Spacer()

            // Match back button — free plan → paywall, pro/black → backend matchBack
            Button(action: {
                if currentUser?.subscriptionPlan == .free {
                    showPaywall = true
                } else {
                    Task { await performMatchBack(profile) }
                }
            }) {
                let isMatched = matchedBack.contains(profile.id)
                let inFlight = inFlightIDs.contains(profile.id)
                HStack(spacing: 6) {
                    if inFlight {
                        ProgressView().scaleEffect(0.6).tint(.black)
                    } else {
                        Image(systemName: isMatched ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                    }
                    Text(isMatched ? "Matched" : "Match Back")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(isMatched ? .black : MatchaTokens.Colors.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isMatched ? MatchaTokens.Colors.accent : MatchaTokens.Colors.accent.opacity(0.15),
                    in: Capsule()
                )
            }
            .disabled(inFlightIDs.contains(profile.id) || matchedBack.contains(profile.id))
        }
        .padding(12)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Match Back action

    private func performMatchBack(_ profile: UserProfile) async {
        guard !inFlightIDs.contains(profile.id),
              !matchedBack.contains(profile.id) else { return }
        inFlightIDs.insert(profile.id)
        defer { inFlightIDs.remove(profile.id) }

        guard let repository else {
            // Fallback без репозитория — mock mode, просто toggling state
            matchedBack.insert(profile.id)
            return
        }

        do {
            let targetId = profile.serverUserId.isEmpty ? profile.id.uuidString : profile.serverUserId
            _ = try await repository.matchBack(targetId: targetId)
            withAnimation(.easeInOut(duration: 0.2)) {
                matchedBack.insert(profile.id)
            }
        } catch {
            errorMessage = "Failed to match. Try again."
        }
    }

    // MARK: - Helpers

    private func avatarPlaceholder(_ profile: UserProfile) -> some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
