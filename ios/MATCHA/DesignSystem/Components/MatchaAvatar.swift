import SwiftUI

// MARK: - AvatarSize

enum AvatarSize {
    case small   // 32 pt
    case medium  // 48 pt
    case large   // 72 pt
    case xlarge  // 120 pt

    var diameter: CGFloat {
        switch self {
        case .small:   return 32
        case .medium:  return 48
        case .large:   return 72
        case .xlarge:  return 120
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small:   return 12
        case .medium:  return 18
        case .large:   return 28
        case .xlarge:  return 44
        }
    }

    var ringWidth: CGFloat {
        switch self {
        case .small:   return 1.5
        case .medium:  return 2
        case .large:   return 2.5
        case .xlarge:  return 3
        }
    }
}

// MARK: - MatchaAvatar

struct MatchaAvatar: View {
    let url: URL?
    let initials: String
    var size: AvatarSize = .medium
    var hasBlueCheck: Bool = false

    var body: some View {
        ZStack {
            avatarContent
                .frame(width: size.diameter, height: size.diameter)
                .clipShape(Circle())
                .overlay {
                    if hasBlueCheck {
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(hex: 0x1DA1F2), Color(hex: 0x1DA1F2).opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: size.ringWidth
                            )
                    } else {
                        Circle()
                            .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                    }
                }

            if hasBlueCheck {
                verifiedBadgeOverlay
            }
        }
        .accessibilityLabel(hasBlueCheck ? "\(initials), blue check" : initials)
    }

    // MARK: - Content states

    @ViewBuilder
    private var avatarContent: some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    shimmerPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity.animation(.easeIn(duration: 0.25)))
                case .failure:
                    failurePlaceholder
                @unknown default:
                    failurePlaceholder
                }
            }
        } else {
            initialsPill
        }
    }

    private var shimmerPlaceholder: some View {
        Circle()
            .fill(MatchaTokens.Colors.elevated)
            .skeleton(isLoading: true)
    }

    private var failurePlaceholder: some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Image(systemName: "person.fill")
                .font(.system(size: size.fontSize * 1.2))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
    }

    private var initialsPill: some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.elevated, MatchaTokens.Colors.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(initials.prefix(2).uppercased())
                .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    // MARK: - Blue Check badge (bottom-right pip)

    @ViewBuilder
    private var verifiedBadgeOverlay: some View {
        if size != .small {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size.fontSize * 0.55))
                .foregroundStyle(Color(hex: 0x1DA1F2))
                .background(
                    Circle()
                        .fill(MatchaTokens.Colors.background)
                        .padding(-3)
                )
                .frame(width: size.diameter, height: size.diameter, alignment: .bottomTrailing)
                .offset(x: 2, y: 2)
        }
    }
}

// MARK: - Preview

#Preview("MatchaAvatar Sizes") {
    HStack(spacing: MatchaTokens.Spacing.large) {
        VStack(spacing: MatchaTokens.Spacing.small) {
            MatchaAvatar(url: nil, initials: "AT", size: .small)
            Text("small").font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        VStack(spacing: MatchaTokens.Spacing.small) {
            MatchaAvatar(url: nil, initials: "AT", size: .medium, hasBlueCheck: true)
            Text("medium blue check").font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        VStack(spacing: MatchaTokens.Spacing.small) {
            MatchaAvatar(url: nil, initials: "RJ", size: .large, hasBlueCheck: true)
            Text("large blue check").font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        VStack(spacing: MatchaTokens.Spacing.small) {
            MatchaAvatar(url: nil, initials: "MK", size: .xlarge)
            Text("xlarge").font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
