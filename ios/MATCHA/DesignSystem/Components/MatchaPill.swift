import SwiftUI

// MARK: - MatchaPill — единый стиль для всех значков/бейджей
//
// Спек дизайна:
// - Text: 10pt bold + tracking 0.6 (UPPERCASE для primary/status badges)
// - Icon: 10pt bold SF Symbol, spacing 3pt от текста
// - Padding: 10 horizontal × 5 vertical
// - Shape: Capsule
// - Variants отражают семантику (accent / info / warning / danger / success / neutral / dark)
//
// Использование:
//   MatchaPill("VERIFIED", icon: "checkmark.shield.fill", variant: .info)
//   MatchaPill("BARTER", variant: .accent)
//   MatchaPill("LAST MINUTE", icon: "clock.fill", variant: .warning)

struct MatchaPill: View {
    enum Variant {
        case accent       // accent bg, black text — APPROVED / BARTER / primary CTA
        case info         // baliBlue tinted — VERIFIED
        case warning      // warning tinted — LAST MINUTE / PAID
        case danger       // danger tinted — cancelled / error
        case success      // success tinted — visited / confirmed
        case neutral      // white 0.06 bg — niche tags / audience
        case dark         // black 0.55 bg + outline — hero overlay pills

        var foreground: Color {
            switch self {
            case .accent: return .black
            case .info: return MatchaTokens.Colors.baliBlue
            case .warning: return MatchaTokens.Colors.warning
            case .danger: return MatchaTokens.Colors.danger
            case .success: return MatchaTokens.Colors.success
            case .neutral: return MatchaTokens.Colors.textSecondary
            case .dark: return .white
            }
        }

        var background: some ShapeStyle {
            switch self {
            case .accent: return AnyShapeStyle(MatchaTokens.Colors.accent)
            case .info: return AnyShapeStyle(MatchaTokens.Colors.baliBlue.opacity(0.2))
            case .warning: return AnyShapeStyle(MatchaTokens.Colors.warning.opacity(0.18))
            case .danger: return AnyShapeStyle(MatchaTokens.Colors.danger.opacity(0.18))
            case .success: return AnyShapeStyle(MatchaTokens.Colors.success.opacity(0.18))
            case .neutral: return AnyShapeStyle(Color.white.opacity(0.06))
            case .dark: return AnyShapeStyle(Color.black.opacity(0.55))
            }
        }

        var borderColor: Color? {
            switch self {
            case .accent: return nil
            case .info: return MatchaTokens.Colors.baliBlue.opacity(0.35)
            case .warning: return MatchaTokens.Colors.warning.opacity(0.4)
            case .danger: return MatchaTokens.Colors.danger.opacity(0.4)
            case .success: return MatchaTokens.Colors.success.opacity(0.4)
            case .neutral: return Color.white.opacity(0.08)
            case .dark: return Color.white.opacity(0.18)
            }
        }
    }

    let text: String
    var icon: String? = nil
    var variant: Variant = .neutral
    /// Uppercase text + letter tracking. Default true для status badges (VERIFIED, BARTER).
    /// Ставь false для niche-chips и tag-ов.
    var uppercase: Bool = true

    init(_ text: String, icon: String? = nil, variant: Variant = .neutral, uppercase: Bool = true) {
        self.text = text
        self.icon = icon
        self.variant = variant
        self.uppercase = uppercase
    }

    var body: some View {
        HStack(spacing: 3) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(uppercase ? text.uppercased() : text)
                .font(.system(size: 10, weight: .bold))
                .tracking(uppercase ? 0.6 : 0)
        }
        .foregroundStyle(variant.foreground)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(variant.background, in: Capsule())
        .overlay {
            if let border = variant.borderColor {
                Capsule().strokeBorder(border, lineWidth: 0.5)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            MatchaPill("VERIFIED", icon: "checkmark.shield.fill", variant: .info)
            MatchaPill("APPROVED", icon: "checkmark.seal.fill", variant: .accent)
            MatchaPill("BLUE CHECK", icon: "checkmark.seal.fill", variant: .info)
        }
        HStack(spacing: 8) {
            MatchaPill("BARTER", variant: .accent)
            MatchaPill("PAID", variant: .warning)
            MatchaPill("LAST MINUTE", icon: "clock.badge.exclamationmark.fill", variant: .warning)
        }
        HStack(spacing: 8) {
            MatchaPill("VISITED", variant: .success)
            MatchaPill("CANCELLED", variant: .danger)
            MatchaPill("3 LEFT", variant: .dark)
        }
        HStack(spacing: 8) {
            MatchaPill("Food", variant: .neutral, uppercase: false)
            MatchaPill("Lifestyle", variant: .neutral, uppercase: false)
            MatchaPill("10K+", variant: .neutral, uppercase: false)
        }
    }
    .padding(24)
    .background(MatchaTokens.Colors.background)
}
