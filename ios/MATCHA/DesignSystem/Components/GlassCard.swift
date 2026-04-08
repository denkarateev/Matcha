import SwiftUI

struct GlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MatchaTokens.Spacing.medium)
            .liquidGlass()
    }
}

struct MatchaSurfaceCard<Content: View>: View {
    private let tint: Color
    private let padding: CGFloat
    private let content: Content

    init(
        tint: Color = MatchaTokens.Colors.accent,
        padding: CGFloat = MatchaTokens.Spacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MatchaTokens.Colors.surfaceSoft.opacity(0.98),
                                MatchaTokens.Colors.elevatedSoft.opacity(0.95),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topLeading) {
                        Circle()
                            .fill(tint.opacity(0.18))
                            .frame(width: 180, height: 180)
                            .blur(radius: 44)
                            .offset(x: -56, y: -80)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.18),
                                        tint.opacity(0.18),
                                        Color.white.opacity(0.06),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
            .matchaShadow(.level2)
    }
}

struct MatchaSectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String
    var badgeText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            if let eyebrow, !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.textMuted)
                    .tracking(1.1)
            }

            HStack(alignment: .top, spacing: MatchaTokens.Spacing.small) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(MatchaTokens.Typography.title2.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    Text(subtitle)
                        .font(MatchaTokens.Typography.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }

                Spacer(minLength: 8)

                if let badgeText, !badgeText.isEmpty {
                    Text(badgeText)
                        .font(MatchaTokens.Typography.caption.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(MatchaTokens.Colors.accent.opacity(0.12), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(MatchaTokens.Colors.accent.opacity(0.18), lineWidth: 1)
                        }
                }
            }
        }
    }
}

struct MatchaMetricTile: View {
    let icon: String
    let label: String
    let value: String
    let footnote: String
    var tint: Color = MatchaTokens.Colors.accent

    var body: some View {
        MatchaSurfaceCard(tint: tint, padding: MatchaTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(value)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(label)
                        .font(MatchaTokens.Typography.caption.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)

                    Text(footnote)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
        }
    }
}

struct MatchaProgressBar: View {
    let progress: Double
    var tint: Color = MatchaTokens.Colors.accent

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint, MatchaTokens.Colors.accentGlow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * clampedProgress, 10))
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(MatchaTokens.Colors.accentGlow)
                            .frame(width: 12, height: 12)
                            .blur(radius: 0.6)
                    }
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

struct MatchaQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var tint: Color = MatchaTokens.Colors.accent

    var body: some View {
        MatchaSurfaceCard(tint: tint, padding: MatchaTokens.Spacing.medium) {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                        .frame(width: 34, height: 34)
                        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(MatchaTokens.Typography.headline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    Text(subtitle)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        }
    }
}
