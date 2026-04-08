import SwiftUI

struct MatchaPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct MatchaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(MatchaTokens.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct MatchaActionButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    let diameter: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(width: diameter, height: diameter)
            .background(background, in: Circle())
            .overlay {
                Circle().strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

// MARK: - Press Animation Style

/// Reusable press-feedback button style: subtle scale + opacity on press.
struct MatchaPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Haptic Helpers

enum MatchaHaptic {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func heavy() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
