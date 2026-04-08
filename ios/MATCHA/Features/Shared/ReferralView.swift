import SwiftUI

// MARK: - ReferralView

/// Displays the user's personal referral code and reward tiers.
struct ReferralView: View {
    let userId: String

    @State private var codeCopied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .padding(.bottom, 4)

                    Text("Invite & Earn")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Share MATCHA with friends and both of you get rewarded")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, MatchaTokens.Spacing.large)

                // Referral code card
                VStack(spacing: 16) {
                    Text("YOUR CODE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .tracking(1.5)

                    Text(referralCode)
                        .font(.system(size: 28, weight: .black, design: .monospaced))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MatchaTokens.Colors.accent.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 1)
                                )
                        )

                    // Copy + Share buttons
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = referralCode
                            withAnimation { codeCopied = true }
                            Task {
                                try? await Task.sleep(for: .seconds(2))
                                withAnimation { codeCopied = false }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                    .font(.caption.weight(.semibold))
                                Text(codeCopied ? "Copied" : "Copy")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                MatchaTokens.Colors.accent.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                        }

                        Button {
                            shareCode()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption.weight(.semibold))
                                Text("Share")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    MatchaTokens.Colors.surface,
                    in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                )

                // Reward tiers
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    Text("REWARDS")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .tracking(1.2)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        rewardRow(
                            emoji: "person.2.fill",
                            scenario: "Blogger invites Blogger",
                            reward: "Both get +5 SuperSwipes",
                            color: MatchaTokens.Colors.warning
                        )

                        rewardDivider

                        rewardRow(
                            emoji: "building.2.fill",
                            scenario: "Blogger invites Business",
                            reward: "Blogger gets +5 SuperSwipes",
                            color: MatchaTokens.Colors.accent
                        )

                        rewardDivider

                        rewardRow(
                            emoji: "briefcase.fill",
                            scenario: "Business invites Business",
                            reward: "Both get 1 week Pro free",
                            color: Color(hex: 0x7EB2FF)
                        )

                        rewardDivider

                        rewardRow(
                            emoji: "person.crop.circle.badge.plus",
                            scenario: "Business invites Blogger",
                            reward: "Business gets +5 SuperSwipes",
                            color: MatchaTokens.Colors.success
                        )
                    }
                    .background(
                        MatchaTokens.Colors.surface,
                        in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    )
                }

                // Fine print
                Text("Rewards are applied once your invited friend completes their first collab.")
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Referral")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Referral Code

    /// Generates a deterministic referral code from the user ID.
    /// Format: MATCHA-XXXXXX (6 alphanumeric chars derived from user ID hash).
    var referralCode: String {
        let hash = userId.utf8.reduce(0) { ($0 &+ UInt64($1)) &* 31 }
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        var code = ""
        var h = hash
        for _ in 0..<6 {
            let index = Int(h % UInt64(chars.count))
            code.append(chars[chars.index(chars.startIndex, offsetBy: index)])
            h /= UInt64(chars.count)
        }
        return "MATCHA-\(code)"
    }

    // MARK: - Actions

    private func shareCode() {
        let shareText = "Join me on MATCHA \u{2615} \u{2014} the collab app for creators and businesses in Bali!\n\nUse my code: \(referralCode)\n\nmatcha.app/join"
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Subviews

    private func rewardRow(
        emoji: String,
        scenario: String,
        reward: String,
        color: Color
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: emoji)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(scenario)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                Text(reward)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }

    private var rewardDivider: some View {
        Divider()
            .background(MatchaTokens.Colors.outline)
            .padding(.leading, MatchaTokens.Spacing.large + 34)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReferralView(userId: "test-user-abc-123")
    }
    .preferredColorScheme(.dark)
}
