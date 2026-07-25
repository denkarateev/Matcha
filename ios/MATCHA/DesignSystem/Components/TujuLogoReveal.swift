import SwiftUI

/// The tuju wordmark reveal: letters rise with a stagger, then the dot drops in
/// with an overshoot and settles into a slow glow pulse.
/// Motion spec: tuju-motion.dc.html · clip 01.
struct TujuLogoReveal: View {
    var fontSize: CGFloat = 44
    /// Set false to render the settled end state without replaying (e.g. previews).
    var animates: Bool = true

    @State private var lettersIn = false
    @State private var dotLanded = false
    @State private var glowing = false

    private let letters = ["t", "u", "j", "u"]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                Text(letter)
                    .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .offset(y: lettersIn ? 0 : 26)
                    .opacity(lettersIn ? 1 : 0)
                    .animation(
                        .smooth(duration: 0.45).delay(0.05 + Double(index) * 0.08),
                        value: lettersIn
                    )
            }

            Circle()
                .fill(MatchaTokens.Colors.accent)
                .frame(width: fontSize * 0.24, height: fontSize * 0.24)
                .shadow(
                    color: MatchaTokens.Colors.accentGlow.opacity(glowing ? 0.85 : 0.4),
                    radius: glowing ? 16 : 7
                )
                .padding(.leading, fontSize * 0.16)
                .offset(y: dotLanded ? 0 : -fontSize * 1.4)
                .scaleEffect(dotLanded ? 1 : 0.01)
                .opacity(dotLanded ? 1 : 0)
                .animation(
                    .spring(response: 0.55, dampingFraction: 0.62).delay(0.45),
                    value: dotLanded
                )
                .animation(
                    .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: glowing
                )
        }
        .task {
            guard animates else {
                lettersIn = true; dotLanded = true; glowing = true
                return
            }
            lettersIn = true
            dotLanded = true
            try? await Task.sleep(for: .milliseconds(1_400))
            glowing = true
        }
    }
}

#Preview {
    TujuLogoReveal()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MatchaTokens.Colors.background)
        .preferredColorScheme(.dark)
}
