import SwiftUI

// MARK: - BadgeType

enum BadgeType {
    case blueCheck
    case new
    case pro
    case bali(String)  // associates a district label

    var icon: String {
        switch self {
        case .blueCheck: return "checkmark.seal.fill"
        case .new:       return "sparkles"
        case .pro:       return "star.fill"
        case .bali:      return "mappin.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .blueCheck:      return "Blue Check"
        case .new:            return "New"
        case .pro:            return "Pro"
        case .bali(let loc):  return loc.isEmpty ? "Bali" : loc
        }
    }

    var foreground: Color {
        switch self {
        case .blueCheck: return .white
        case .new:       return .black
        case .pro:       return .black
        case .bali:      return MatchaTokens.Colors.textPrimary
        }
    }

    var background: Color {
        switch self {
        case .blueCheck: return Color(hex: 0x1DA1F2)
        case .new:       return MatchaTokens.Colors.warning
        case .pro:       return MatchaTokens.Colors.warning
        case .bali:      return Color.white.opacity(0.18)
        }
    }

    var borderColor: Color {
        switch self {
        case .bali: return Color.white.opacity(0.28)
        default:    return .clear
        }
    }
}

// MARK: - BadgeSize

enum BadgeSize {
    case small
    case regular

    var iconSize: CGFloat { self == .small ? 9 : 11 }
    var font: Font { self == .small ? MatchaTokens.Typography.caption : Font.system(size: 13, weight: .semibold) }
    var hPad: CGFloat { self == .small ? 7 : 10 }
    var vPad: CGFloat { self == .small ? 3 : 5 }
}

// MARK: - MatchaBadge

struct MatchaBadge: View {
    let type: BadgeType
    var size: BadgeSize = .regular

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(type.foreground)

            Text(type.label)
                .font(size.font)
                .foregroundStyle(type.foreground)
        }
        .padding(.horizontal, size.hPad)
        .padding(.vertical, size.vPad)
        .background(type.background, in: Capsule())
        .overlay(Capsule().strokeBorder(type.borderColor, lineWidth: 1))
        .accessibilityLabel(type.label)
    }
}

// MARK: - Preview

#Preview("MatchaBadge") {
    HStack(spacing: MatchaTokens.Spacing.small) {
        MatchaBadge(type: .blueCheck)
        MatchaBadge(type: .new)
        MatchaBadge(type: .pro)
        MatchaBadge(type: .bali("Seminyak"))
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
