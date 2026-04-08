import SwiftUI

// MARK: - ProfileCardData

/// Data model for the swipe card. Decoupled from domain models so the
/// component is fully reusable across feed and search contexts.
struct ProfileCardData: Identifiable {
    let id: String
    let photoURL: URL?
    let name: String
    let age: Int?
    let district: String?
    let lookingFor: String?
    let collabCount: Int
    let hasBlueCheck: Bool
    let niches: [String]
    let statLine: String?   // e.g. "12.4K followers"
}

// MARK: - ProfileCard

struct ProfileCard: View {
    let data: ProfileCardData
    var onSwipe: ((SwipeDirection) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    // Thresholds
    private let swipeThreshold: CGFloat = 100
    private let maxRotation: CGFloat = 18

    private var rotationAngle: Double {
        Double(dragOffset.width / 20)
    }

    private var likeOpacity: Double {
        min(1, max(0, Double(dragOffset.width) / swipeThreshold))
    }

    private var nopeOpacity: Double {
        min(1, max(0, Double(-dragOffset.width) / swipeThreshold))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Background photo
            photoBackground

            // MARK: Gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.45),
                    .init(color: .black.opacity(0.5), location: 0.7),
                    .init(color: .black.opacity(0.88), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(MatchaTokens.Radius.card, corners: .allCorners)

            // MARK: Info panel
            VStack(alignment: .leading, spacing: 0) {
                topBadges
                Spacer()
                infoPanel
            }
            .padding(MatchaTokens.Spacing.large)

            // MARK: Swipe overlays
            likeLabel
            nopeLabel
        }
        .clipShape(RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        .matchaShadow(MatchaTokens.Shadow.level3)
        .rotationEffect(.degrees(rotationAngle))
        .offset(y: isDragging ? dragOffset.height * 0.15 : 0)
        .animation(isDragging ? nil : MatchaTokens.Animations.cardAppear, value: dragOffset)
        .gesture(swipeGesture)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .sensoryFeedback(.impact(weight: .light), trigger: dragOffset.width > swipeThreshold || dragOffset.width < -swipeThreshold)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var photoBackground: some View {
        if let url = data.photoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProfileCardSkeleton()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity.animation(.easeIn(duration: 0.3)))
                case .failure:
                    fallbackPhoto
                @unknown default:
                    fallbackPhoto
                }
            }
        } else {
            fallbackPhoto
        }
    }

    private var fallbackPhoto: some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.heroGradientTop, MatchaTokens.Colors.heroGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "person.crop.rectangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.35))
        }
    }

    @ViewBuilder
    private var topBadges: some View {
        HStack(spacing: MatchaTokens.Spacing.xSmall) {
            if data.hasBlueCheck {
                MatchaBadge(type: .blueCheck, size: .regular)
            }
            if let district = data.district {
                MatchaBadge(type: .bali(district), size: .regular)
            }
            Spacer()
            if data.collabCount > 0 {
                completedCollabsBadge
            }
        }
    }

    private var completedCollabsBadge: some View {
        Text("\(data.collabCount) collabs")
            .font(MatchaTokens.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            // Name + age
            HStack(alignment: .firstTextBaseline, spacing: MatchaTokens.Spacing.xSmall) {
                Text(data.name)
                    .font(MatchaTokens.Typography.heroTitle)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                if let age = data.age {
                    Text("\(age)")
                        .font(MatchaTokens.Typography.title2)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }

            // Looking for
            if let lookingFor = data.lookingFor {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text("Looking for: \(lookingFor)")
                        .font(MatchaTokens.Typography.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }

            // Stats + niches glass strip
            if data.statLine != nil || !data.niches.isEmpty {
                glassStatsStrip
            }
        }
    }

    private var glassStatsStrip: some View {
        HStack(spacing: MatchaTokens.Spacing.small) {
            if let stat = data.statLine {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text(stat)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                }
            }

            if !data.niches.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MatchaTokens.Spacing.xSmall) {
                        ForEach(data.niches.prefix(4), id: \.self) { niche in
                            Text(niche)
                                .font(MatchaTokens.Typography.caption)
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, MatchaTokens.Spacing.small)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - LIKE / NOPE overlays

    private var likeLabel: some View {
        VStack {
            HStack {
                Text("LIKE")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(MatchaTokens.Colors.accent, lineWidth: 4)
                    )
                    .rotationEffect(.degrees(-20))
                    .opacity(likeOpacity)
                    .padding(.top, MatchaTokens.Spacing.large)
                    .padding(.leading, MatchaTokens.Spacing.large)
                Spacer()
            }
            Spacer()
        }
    }

    private var nopeLabel: some View {
        VStack {
            HStack {
                Spacer()
                Text("NOPE")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.danger)
                    .padding(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(MatchaTokens.Colors.danger, lineWidth: 4)
                    )
                    .rotationEffect(.degrees(20))
                    .opacity(nopeOpacity)
                    .padding(.top, MatchaTokens.Spacing.large)
                    .padding(.trailing, MatchaTokens.Spacing.large)
            }
            Spacer()
        }
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                let dx = value.translation.width

                if dx > swipeThreshold {
                    withAnimation(MatchaTokens.Animations.cardDismiss) {
                        dragOffset = CGSize(width: 500, height: value.translation.height)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe?(.right)
                    }
                } else if dx < -swipeThreshold {
                    withAnimation(MatchaTokens.Animations.cardDismiss) {
                        dragOffset = CGSize(width: -500, height: value.translation.height)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSwipe?(.left)
                    }
                } else {
                    withAnimation(MatchaTokens.Animations.cardAppear) {
                        dragOffset = .zero
                    }
                }
            }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [data.name]
        if let age = data.age { parts.append("\(age) years old") }
        if let district = data.district { parts.append(district) }
        if let lookingFor = data.lookingFor { parts.append("Looking for \(lookingFor)") }
        if data.hasBlueCheck { parts.append("Blue Check verified") }
        if data.collabCount > 0 { parts.append("\(data.collabCount) completed collabs") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Corner helper

private extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("ProfileCard") {
    ZStack {
        MatchaTokens.Colors.background.ignoresSafeArea()

        ProfileCard(
            data: ProfileCardData(
                id: "1",
                photoURL: nil,
                name: "Ari",
                age: 26,
                district: "Seminyak",
                lookingFor: "Restaurant collab",
                collabCount: 12,
                hasBlueCheck: true,
                niches: ["Food & Bev", "Lifestyle", "Travel"],
                statLine: "18.2K followers"
            ),
            onSwipe: { direction in
                print("Swiped \(direction)")
            }
        )
        .padding(MatchaTokens.Spacing.large)
        .frame(height: 520)
    }
    .preferredColorScheme(.dark)
}
