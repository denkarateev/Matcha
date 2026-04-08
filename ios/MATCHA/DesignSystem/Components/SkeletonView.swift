import SwiftUI

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    var isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            content
                .overlay {
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.0), location: 0),
                                .init(color: .white.opacity(0.08), location: 0.45),
                                .init(color: .white.opacity(0.18), location: 0.5),
                                .init(color: .white.opacity(0.08), location: 0.55),
                                .init(color: .white.opacity(0.0), location: 1)
                            ],
                            startPoint: .init(x: phase, y: 0),
                            endPoint: .init(x: phase + 1, y: 0)
                        )
                        .frame(width: w * 3)
                        .offset(x: -w + (w * 3 * (phase + 1) / 2))
                    }
                    .clipped()
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    /// Apply shimmer loading effect over this view.
    func skeleton(isLoading: Bool) -> some View {
        modifier(ShimmerModifier(isLoading: isLoading))
    }
}

// MARK: - SkeletonView

/// A rectangle-shaped placeholder that shimmers during loading.
struct SkeletonView: View {
    var cornerRadius: CGFloat = 12
    var height: CGFloat? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(MatchaTokens.Colors.elevated)
            .frame(height: height)
            .skeleton(isLoading: true)
    }
}

// MARK: - ProfileCardSkeleton

/// Full profile card placeholder while photo and data load.
struct ProfileCardSkeleton: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            // Photo placeholder
            RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                .fill(MatchaTokens.Colors.elevated)
                .frame(maxWidth: .infinity)
                .aspectRatio(3/4, contentMode: .fit)
                .skeleton(isLoading: true)

            // Glass info strip at bottom
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                // Name + age
                SkeletonView(cornerRadius: 6, height: 22)
                    .frame(width: 160)

                // Secondary line
                SkeletonView(cornerRadius: 6, height: 16)
                    .frame(width: 120)

                // Tags row
                HStack(spacing: MatchaTokens.Spacing.xSmall) {
                    SkeletonView(cornerRadius: MatchaTokens.Radius.pill, height: 28)
                        .frame(width: 80)
                    SkeletonView(cornerRadius: MatchaTokens.Radius.pill, height: 28)
                        .frame(width: 64)
                    SkeletonView(cornerRadius: MatchaTokens.Radius.pill, height: 28)
                        .frame(width: 96)
                }
            }
            .padding(MatchaTokens.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        }
        .accessibilityLabel("Loading profile")
        .accessibilityHidden(true)
    }
}

// MARK: - Offer Card Skeleton

struct OfferCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            HStack(spacing: MatchaTokens.Spacing.medium) {
                // Avatar
                Circle()
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: 48, height: 48)
                    .skeleton(isLoading: true)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonView(cornerRadius: 6, height: 16).frame(width: 140)
                    SkeletonView(cornerRadius: 6, height: 13).frame(width: 90)
                }
                Spacer()
            }
            SkeletonView(cornerRadius: 6, height: 16).frame(width: 200)
            SkeletonView(cornerRadius: 6, height: 13).frame(maxWidth: .infinity)
            SkeletonView(cornerRadius: 6, height: 13).frame(width: 160)
        }
        .padding(MatchaTokens.Spacing.medium)
        .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        .skeleton(isLoading: true)
        .accessibilityHidden(true)
    }
}

// MARK: - Chat Row Skeleton

/// Placeholder for a single chat conversation row.
struct ChatRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(MatchaTokens.Colors.elevated)
                .frame(width: 52, height: 52)
                .skeleton(isLoading: true)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(cornerRadius: 6, height: 16).frame(width: 120)
                SkeletonView(cornerRadius: 6, height: 13).frame(width: 180)
            }

            Spacer()

            SkeletonView(cornerRadius: 6, height: 12).frame(width: 36)
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.vertical, 12)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Skeletons") {
    ScrollView {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            Text("Profile Card Skeleton")
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .font(MatchaTokens.Typography.caption)

            ProfileCardSkeleton()

            Text("Offer Card Skeleton")
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .font(MatchaTokens.Typography.caption)

            OfferCardSkeleton()

            Text("Shimmer line rows")
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .font(MatchaTokens.Typography.caption)

            VStack(alignment: .leading, spacing: 10) {
                SkeletonView(cornerRadius: 8, height: 20).frame(maxWidth: .infinity)
                SkeletonView(cornerRadius: 8, height: 16).frame(width: 220)
                SkeletonView(cornerRadius: 8, height: 16).frame(width: 160)
            }
        }
        .padding(MatchaTokens.Spacing.large)
    }
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
