import SwiftUI

// MARK: - LottieView
//
// Conditionally wraps the Lottie framework when available.
// If Lottie is not installed, a functional fallback animation is rendered.
//
// Add Lottie via Swift Package Manager:
//   https://github.com/airbnb/lottie-spm.git  (from 4.0.0)
//
// After adding the package, the #if canImport(Lottie) block activates automatically.

#if canImport(Lottie)
import Lottie

// MARK: - Real Lottie wrapper

struct LottieView: UIViewRepresentable {
    let name: String
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: Double = 1.0
    var completion: ((Bool) -> Void)? = nil

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(name: name)
        view.loopMode = loopMode
        view.animationSpeed = animationSpeed
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .pauseAndRestore
        view.play(completion: completion)
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.loopMode = loopMode
        uiView.animationSpeed = animationSpeed
    }

    /// Plays once then calls the completion closure.
    func playOnce(completion: @escaping (Bool) -> Void) -> LottieView {
        var copy = self
        copy.loopMode = .playOnce
        copy.completion = completion
        return copy
    }
}

#else

// MARK: - Fallback animation (no Lottie dependency)

struct LottieView: View {
    let name: String
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: Double = 1.0
    var completion: ((Bool) -> Void)? = nil

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.6
    @State private var hasPlayed = false

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            MatchaTokens.Colors.accent,
                            MatchaTokens.Colors.accentMuted,
                            MatchaTokens.Colors.accent.opacity(0)
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .rotationEffect(.degrees(rotation))
                .frame(width: 80, height: 80)

            // Inner pulse
            Circle()
                .fill(MatchaTokens.Colors.accent.opacity(0.15))
                .scaleEffect(scale)
                .frame(width: 56, height: 56)

            // Icon — map animation name to an SF symbol
            Image(systemName: iconForName(name))
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.accent)
                .opacity(opacity)
        }
        .onAppear { startFallbackAnimation() }
        .accessibilityLabel("Loading animation")
        .accessibilityHidden(true)
    }

    private func iconForName(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("match")   { return "heart.fill" }
        if lower.contains("load")    { return "arrow.2.circlepath" }
        if lower.contains("success") { return "checkmark.seal.fill" }
        if lower.contains("star")    { return "star.fill" }
        if lower.contains("matcha")  { return "leaf.fill" }
        return "sparkles"
    }

    private func startFallbackAnimation() {
        switch loopMode {
        case .loop:
            withAnimation(.linear(duration: 1.8 / animationSpeed).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.0 / animationSpeed).repeatForever(autoreverses: true)) {
                scale = 1.1
                opacity = 1.0
            }

        case .playOnce:
            withAnimation(.easeInOut(duration: 1.5 / animationSpeed)) {
                rotation = 360
                scale = 1.1
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 / animationSpeed) {
                if !hasPlayed {
                    hasPlayed = true
                    completion?(true)
                }
            }

        default:
            withAnimation(.linear(duration: 1.8 / animationSpeed).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    func playOnce(completion: @escaping (Bool) -> Void) -> LottieView {
        var copy = self
        copy.loopMode = .playOnce
        copy.completion = completion
        return copy
    }
}

// MARK: - LottieLoopMode stub (mirrors Lottie enum for source compatibility)

enum LottieLoopMode {
    case loop
    case playOnce
    case autoReverse
    case `repeat`(Float)
    case repeatBackwards(Float)
}

#endif

// MARK: - Preview

#Preview("LottieView fallback") {
    VStack(spacing: MatchaTokens.Spacing.large) {
        LottieView(name: "matcha-match", loopMode: .loop)
            .frame(width: 120, height: 120)

        LottieView(name: "success", loopMode: .loop)
            .frame(width: 120, height: 120)

        LottieView(name: "loading", loopMode: .loop)
            .frame(width: 120, height: 120)
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
