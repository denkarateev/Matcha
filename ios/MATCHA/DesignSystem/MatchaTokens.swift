import SwiftUI

enum MatchaTokens {
    enum Colors {
        // Original MATCHA — clean dark + lime green
        static let background = Color(hex: 0x050505)
        static let surface = Color(hex: 0x101314)
        static let surfaceSoft = Color(hex: 0x141918)
        static let elevated = Color(hex: 0x171C1B)
        static let elevatedSoft = Color(hex: 0x1C2321)
        static let accent = Color(hex: 0xB8FF43)       // matcha lime
        static let accentMuted = Color(hex: 0x6F8F31)
        static let accentGlow = Color(hex: 0xD8FF8F)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.72)
        static let textMuted = Color.white.opacity(0.48)
        static let outline = Color.white.opacity(0.14)
        static let success = Color(hex: 0x56D987)
        static let warning = Color(hex: 0xFFB84D)
        static let danger = Color(hex: 0xFF6B6B)
        static let baliBlue = Color(hex: 0x74C6FF)
        static let sand = Color(hex: 0xE8C98A)
        static let heroGradientTop = Color(hex: 0x1A2E13)
        static let heroGradientBottom = Color(hex: 0x090C08)
        static let gradientStart = Color(hex: 0x0A1A0D)
        static let gradientEnd = Color(hex: 0x0D0A15)

        // Liquid Glass palette — slightly brighter
        static let glassFill = Color.white.opacity(0.07)
        static let glassBorder = Color.white.opacity(0.14)
        static let glassBorderLight = Color.white.opacity(0.20)
        static let glassHighlight = Color.white.opacity(0.10)
    }

    /// Subtle dark gradient background (green → black → purple) replacing flat black
    static var backgroundGradient: some View {
        LinearGradient(
            colors: [Colors.gradientStart, Colors.background, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 24
        static let pill: CGFloat = 999
        static let button: CGFloat = 18
    }

    // MARK: - Typography
    enum Typography {
        static let heroTitle = Font.system(size: 32, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .bold)
        static let title2 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
    }

    // MARK: - Shadows
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        static let level1 = Shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 4)
        static let level2 = Shadow(color: .black.opacity(0.40), radius: 16, x: 0, y: 8)
        static let level3 = Shadow(color: .black.opacity(0.50), radius: 24, x: 0, y: 12)
    }

    // MARK: - Animations
    enum Animations {
        static let cardAppear   = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let cardDismiss  = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let tabSwitch    = Animation.easeInOut(duration: 0.2)
        static let sheetPresent = Animation.spring(response: 0.35, dampingFraction: 0.85)
        static let buttonPress  = Animation.spring(response: 0.2, dampingFraction: 0.6)
        static let matchReveal  = Animation.spring(response: 0.5, dampingFraction: 0.65)
    }
}

// MARK: - View shadow helper
extension View {
    func matchaShadow(_ shadow: MatchaTokens.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    /// Liquid glass surface — frosted blur + subtle border highlight + inner glow
    func liquidGlass(cornerRadius: CGFloat = MatchaTokens.Radius.card) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        // Top highlight — simulates light refraction
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        MatchaTokens.Colors.glassHighlight,
                                        Color.clear,
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        MatchaTokens.Colors.glassBorderLight,
                                        MatchaTokens.Colors.glassBorder,
                                        MatchaTokens.Colors.glassBorder.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }
            }
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }

    /// Compact liquid glass pill (for buttons, badges, chips)
    func liquidGlassPill() -> some View {
        self.liquidGlass(cornerRadius: MatchaTokens.Radius.pill)
    }

    /// Conditional liquid glass — only applies if the condition is true
    @ViewBuilder
    func conditionalLiquidGlass(_ condition: Bool, cornerRadius: CGFloat = MatchaTokens.Radius.card) -> some View {
        if condition {
            self.liquidGlass(cornerRadius: cornerRadius)
        } else {
            self
        }
    }

    /// Liquid glass card with padding
    func liquidGlassCard(padding: CGFloat = MatchaTokens.Spacing.medium) -> some View {
        self
            .padding(padding)
            .liquidGlass()
    }
}

extension Color {
    init(hex: UInt64, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
