import SwiftUI

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MatchaTokens.Spacing.large) {
            iconView
            textBlock
            if let ctaTitle, let ctaAction {
                ctaButton(title: ctaTitle, action: ctaAction)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MatchaTokens.Spacing.xLarge)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    // MARK: - Sub-views

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            MatchaTokens.Colors.accent.opacity(0.18),
                            MatchaTokens.Colors.accent.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 56
                    )
                )
                .frame(width: 112, height: 112)

            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [MatchaTokens.Colors.accent, MatchaTokens.Colors.accentMuted],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var textBlock: some View {
        VStack(spacing: MatchaTokens.Spacing.small) {
            Text(title)
                .font(MatchaTokens.Typography.title2)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(MatchaTokens.Typography.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private func ctaButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(MatchaPrimaryButtonStyle())
            .frame(maxWidth: 280)
            .accessibilityLabel(title)
    }
}

// MARK: - Preview

#Preview("EmptyStateView") {
    VStack(spacing: MatchaTokens.Spacing.large) {
        EmptyStateView(
            icon: "cup.and.saucer.fill",
            title: "You've finished your cup",
            subtitle: "Come back tomorrow for a fresh brew, or broaden your filters to see more creators.",
            ctaTitle: "Adjust filters"
        ) {
            print("CTA tapped")
        }

        Divider().opacity(0.2)

        EmptyStateView(
            icon: "tag.slash",
            title: "No offers right now",
            subtitle: "Businesses haven't posted near you yet. Check back soon.",
            ctaTitle: nil
        )
    }
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
