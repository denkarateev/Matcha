import SwiftUI

// MARK: - DealStatus Visual Properties Extension

extension DealStatus {
    var displayTitle: String {
        switch self {
        case .draft:      return "Draft"
        case .confirmed:  return "Confirmed"
        case .visited:    return "Visited"
        case .reviewed:   return "Reviewed"
        case .noShow:     return "No Show"
        case .cancelled:  return "Cancelled"
        }
    }

    var icon: String {
        switch self {
        case .draft:      return "pencil.circle"
        case .confirmed:  return "checkmark.circle.fill"
        case .visited:    return "location.fill"
        case .reviewed:   return "star.fill"
        case .noShow:     return "person.fill.xmark"
        case .cancelled:  return "xmark.circle.fill"
        }
    }

    var badgeForeground: Color {
        switch self {
        case .draft:      return Color.white.opacity(0.72)
        case .confirmed:  return .black
        case .visited:    return .black
        case .reviewed:   return .black
        case .noShow:     return Color.white.opacity(0.72)
        case .cancelled:  return Color.white.opacity(0.72)
        }
    }

    var badgeBackground: Color {
        switch self {
        case .draft:      return Color.white.opacity(0.12)
        case .confirmed:  return MatchaTokens.Colors.success
        case .visited:    return MatchaTokens.Colors.accent
        case .reviewed:   return MatchaTokens.Colors.warning
        case .noShow:     return Color.white.opacity(0.12)
        case .cancelled:  return MatchaTokens.Colors.danger.opacity(0.25)
        }
    }

    var badgeBorderColor: Color {
        switch self {
        case .noShow:    return MatchaTokens.Colors.danger.opacity(0.5)
        case .cancelled: return MatchaTokens.Colors.danger.opacity(0.5)
        default:         return .clear
        }
    }
}

// MARK: - DealStatusBadge

struct DealStatusBadge: View {
    let status: DealStatus
    var compact: Bool = false  // icon-only compact mode

    var body: some View {
        HStack(spacing: compact ? 0 : 5) {
            Image(systemName: status.icon)
                .font(.system(size: compact ? 12 : 11, weight: .semibold))
                .foregroundStyle(status.badgeForeground)

            if !compact {
                Text(status.displayTitle)
                    .font(MatchaTokens.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(status.badgeForeground)
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(status.badgeBackground, in: Capsule())
        .overlay(Capsule().strokeBorder(status.badgeBorderColor, lineWidth: 1))
        .accessibilityLabel(status.displayTitle)
        .accessibilityIdentifier("deal-status-badge")
    }
}

// MARK: - Preview

#Preview("DealStatusBadge") {
    VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
        Text("Full badges")
            .font(MatchaTokens.Typography.caption)
            .foregroundStyle(MatchaTokens.Colors.textSecondary)

        VStack(alignment: .leading, spacing: 8) {
            ForEach(DealStatus.allCases, id: \.self) { status in
                DealStatusBadge(status: status)
            }
        }

        Text("Compact (icon-only)")
            .font(MatchaTokens.Typography.caption)
            .foregroundStyle(MatchaTokens.Colors.textSecondary)

        HStack(spacing: MatchaTokens.Spacing.small) {
            ForEach(DealStatus.allCases, id: \.self) { status in
                DealStatusBadge(status: status, compact: true)
            }
        }
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
