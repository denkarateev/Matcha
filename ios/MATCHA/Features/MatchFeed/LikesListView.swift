import SwiftUI

// MARK: - LikesListView

/// Shows profiles that have liked the current user.
/// Opened as a sheet from the pending likes pill in MatchFeedView.
struct LikesListView: View {
    let profiles: [UserProfile]
    @State private var matchedBack: Set<UUID> = []
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

            // Match back button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if matchedBack.contains(profile.id) {
                        matchedBack.remove(profile.id)
                    } else {
                        matchedBack.insert(profile.id)
                    }
                }
            }) {
                let isMatched = matchedBack.contains(profile.id)
                HStack(spacing: 6) {
                    Image(systemName: isMatched ? "heart.fill" : "heart")
                        .font(.system(size: 13))
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
        }
        .padding(12)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
