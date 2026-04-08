import SwiftUI

// MARK: - Matcha Brewing Animation (Loading State)

struct MatchaBrewingAnimation: View {
    @State private var cupScale: CGFloat = 0.8
    @State private var steamPhase: CGFloat = 0
    @State private var liquidLevel: CGFloat = 0
    @State private var leafRotation: Double = 0
    @State private var pulseOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(MatchaTokens.Colors.accent.opacity(pulseOpacity), lineWidth: 2)
                .scaleEffect(cupScale + 0.3)

            // Cup body
            ZStack {
                // Cup background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: 60, height: 52)
                    .offset(y: 8)

                // Matcha liquid filling up
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MatchaTokens.Colors.accent.opacity(0.8),
                                MatchaTokens.Colors.accentMuted
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 52, height: 44 * liquidLevel)
                    .offset(y: 8 + (44 * (1 - liquidLevel)) / 2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Cup handle
                Circle()
                    .stroke(MatchaTokens.Colors.elevated, lineWidth: 4)
                    .frame(width: 18, height: 18)
                    .offset(x: 36, y: 8)

                // Steam particles
                ForEach(0..<3, id: \.self) { i in
                    SteamParticle(
                        delay: Double(i) * 0.4,
                        phase: steamPhase
                    )
                    .offset(x: CGFloat(i - 1) * 12, y: -22)
                }
            }
            .scaleEffect(cupScale)

            // Floating leaf
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundStyle(MatchaTokens.Colors.accent)
                .rotationEffect(.degrees(leafRotation))
                .offset(x: 0, y: -4)
                .opacity(liquidLevel > 0.5 ? 1 : 0)
        }
        .onAppear {
            // Cup scale in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                cupScale = 1.0
            }

            // Liquid fill
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                liquidLevel = 1.0
            }

            // Steam
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                steamPhase = 1.0
            }

            // Leaf rotation
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                leafRotation = 15
            }

            // Pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.1
            }
        }
    }
}

// MARK: - Steam Particle

private struct SteamParticle: View {
    let delay: Double
    let phase: CGFloat

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(MatchaTokens.Colors.accent.opacity(opacity))
            .frame(width: 4, height: 4)
            .offset(y: yOffset)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    yOffset = -30
                    opacity = 0
                }
                // Initial opacity
                withAnimation(
                    .easeIn(duration: 0.3)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    opacity = 0.6
                }
            }
    }
}

// MARK: - Match Celebration Particles (Matcha Green Burst)

struct MatchCelebrationParticles: View {
    let particleCount: Int

    @State private var particles: [CelebrationParticle] = []
    @State private var animationPhase: Bool = false

    init(particleCount: Int = 28) {
        self.particleCount = particleCount
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(animationPhase ? particle.endScale : 0.01)
                    .opacity(animationPhase ? 0 : particle.startOpacity)
                    .offset(
                        x: animationPhase ? particle.endX : 0,
                        y: animationPhase ? particle.endY : 0
                    )
            }
        }
        .onAppear { spawnAndAnimate() }
    }

    private func spawnAndAnimate() {
        let accentColor = MatchaTokens.Colors.accent // #B8FF43
        let colors: [Color] = [
            accentColor,
            accentColor.opacity(0.8),
            accentColor.opacity(0.6),
            MatchaTokens.Colors.accentGlow,
            .white.opacity(0.9)
        ]

        for i in 0..<particleCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 80...220)
            let particle = CelebrationParticle(
                id: i,
                endX: cos(angle) * distance,
                endY: sin(angle) * distance,
                size: CGFloat.random(in: 5...14),
                color: colors[i % colors.count],
                startOpacity: Double.random(in: 0.7...1.0),
                endScale: CGFloat.random(in: 0.3...1.2)
            )
            particles.append(particle)
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            animationPhase = true
        }
    }
}

private struct CelebrationParticle: Identifiable {
    let id: Int
    var endX: CGFloat
    var endY: CGFloat
    var size: CGFloat
    var color: Color
    var startOpacity: Double
    var endScale: CGFloat
}

// MARK: - Skeleton Shimmer Loading Card

struct SkeletonCardView: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
            .fill(MatchaTokens.Colors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                MatchaTokens.Colors.elevated.opacity(0.5),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
            }
            .clipShape(RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

// MARK: - Preview

#Preview("Matcha Brewing") {
    ZStack {
        MatchaTokens.Colors.background.ignoresSafeArea()
        MatchaBrewingAnimation()
            .frame(width: 120, height: 120)
    }
    .preferredColorScheme(.dark)
}

#Preview("Match Celebration") {
    ZStack {
        Color.black.opacity(0.88).ignoresSafeArea()
        MatchCelebrationParticles()
    }
    .preferredColorScheme(.dark)
}
