import SwiftUI

// MARK: - ProfileDetailView

/// Shows another user's public profile — not the current user's own profile.
struct ProfileDetailView: View {
    let profile: UserProfile
    var repository: any MatchaRepository = APIMatchaRepository()
    @State private var showMessageAlert = false
    @State private var showChat = false
    @State private var liked = false
    @State private var showBlockReport = false
    @State private var ugcPosts: [UGCPost] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) { bottomBar }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Menu {
                        Button(action: { showBlockReport = true }) {
                            Label("Block or Report", systemImage: "exclamationmark.shield")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .alert("Message \(profile.name)", isPresented: $showMessageAlert) {
            Button("Open Chat", role: .none) { showChat = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Start a conversation with \(profile.name)?")
        }
        .sheet(isPresented: $showChat) {
            NavigationStack {
                ChatConversationView(chat: ChatPreview(
                    id: UUID(),
                    partner: profile,
                    lastMessage: "",
                    timestampText: "",
                    unreadCount: 0,
                    translationNote: nil,
                    isMuted: false
                ), repository: repository)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .sheet(isPresented: $showBlockReport) {
            BlockReportView(
                profile: profile,
                onBlock: { dismiss() },
                onReport: {}
            )
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let url = profile.photoURL {
                    GeometryReader { geo in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 440)
                                    .clipped()
                            default:
                                heroGradientPlaceholder
                                    .frame(width: geo.size.width, height: 440)
                            }
                        }
                    }
                    .frame(height: 440)
                } else {
                    heroGradientPlaceholder
                        .frame(height: 440)
                }
            }

            // Bottom gradient — subtle, same as card style
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.5),
                    .init(color: MatchaTokens.Colors.background.opacity(0.55), location: 0.75),
                    .init(color: MatchaTokens.Colors.background, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 440)

            // Name & metadata — Aria Moon style
            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                // Name + role inline (like card)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(profile.name)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)

                    Text(profile.secondaryLine)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))

                    if profile.hasBlueCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: 0x1DA1F2))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                // Location
                if let location = profile.district ?? profile.locationDistrict {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(location)
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.bottom, MatchaTokens.Spacing.large)
        }
        .frame(height: 440)
    }

    private var heroGradientPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.heroGradientTop, MatchaTokens.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.2))
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.large) {
            // Niche tags — full set, wrapping
            if !profile.niches.isEmpty { nichesSection }
            // Stats bar — Rating | Collabs | Followers
            statsRow
            if !profile.bio.isEmpty { bioSection }
            collabSection
            if profile.role == .business && !ugcPosts.isEmpty {
                UGCGalleryView(posts: ugcPosts, isOwner: false)
            }
            if !profile.photoURLs.isEmpty { gallerySection }
        }
        .padding(.top, MatchaTokens.Spacing.medium)
        .padding(.bottom, 120)
        .task { await loadUGCPosts() }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            if let rating = profile.rating {
                statBarItem(
                    icon: "star.fill",
                    iconColor: MatchaTokens.Colors.warning,
                    value: String(format: "%.1f", rating),
                    label: "Rating"
                )
                statBarDivider
            }

            statBarItem(
                icon: "checkmark.circle.fill",
                iconColor: MatchaTokens.Colors.success,
                value: "\(profile.completedCollabsCount)",
                label: "Collabs"
            )

            if let followers = profile.followersCount {
                statBarDivider
                statBarItem(
                    icon: "person.2.fill",
                    iconColor: Color(hex: 0x7EB2FF),
                    value: formatCount(followers),
                    label: "Followers"
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, MatchaTokens.Spacing.large)
    }

    private func statBarItem(icon: String, iconColor: Color, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statBarDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 32)
    }

    // MARK: - Bio

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            sectionHeader("About")

            Text(profile.bio)
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineSpacing(4)
                .padding(MatchaTokens.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlass()
                .padding(.horizontal, MatchaTokens.Spacing.large)
        }
    }

    // MARK: - Niches

    private var nichesSection: some View {
        FlowLayout(spacing: 8) {
            ForEach(profile.niches, id: \.self) { niche in
                Text(niche)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
    }


    // MARK: - Collab

    private var collabSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            sectionHeader("Collaboration")

            VStack(spacing: 0) {
                collabRow(
                    icon: "arrow.trianglehead.2.counterclockwise.rotate.90",
                    label: "Type",
                    value: profile.collaborationType.title,
                    color: collabTypeColor(profile.collaborationType)
                )

                if !profile.languages.isEmpty {
                    Divider().background(MatchaTokens.Colors.outline).padding(.leading, 54)

                    collabRow(
                        icon: "globe",
                        label: "Languages",
                        value: profile.languages.joined(separator: ", "),
                        color: Color(hex: 0x7EB2FF)
                    )
                }

                if !profile.niches.isEmpty {
                    Divider().background(MatchaTokens.Colors.outline).padding(.leading, 54)

                    collabRow(
                        icon: "tag.fill",
                        label: "Audience",
                        value: profile.audience,
                        color: MatchaTokens.Colors.accent
                    )
                }
            }
            .liquidGlass()
            .padding(.horizontal, MatchaTokens.Spacing.large)
        }
    }

    private func collabRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }

    private func collabTypeColor(_ type: CollaborationType) -> Color {
        switch type {
        case .paid:   return MatchaTokens.Colors.success
        case .barter: return MatchaTokens.Colors.warning
        case .both:   return MatchaTokens.Colors.accent
        }
    }

    // MARK: - Gallery

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            sectionHeader("Gallery")
                .padding(.horizontal, MatchaTokens.Spacing.large)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MatchaTokens.Spacing.small) {
                    ForEach(Array(profile.photoURLs.prefix(6).enumerated()), id: \.offset) { _, url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 160, height: 200)
                                    .clipped()
                            default:
                                MatchaTokens.Colors.elevated
                                    .frame(width: 160, height: 200)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(MatchaTokens.Colors.outline)

            HStack(spacing: MatchaTokens.Spacing.small) {
                // Like button
                Button(action: { withAnimation(MatchaTokens.Animations.buttonPress) { liked.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(liked ? MatchaTokens.Colors.danger : MatchaTokens.Colors.textSecondary)
                        Text(liked ? "Liked" : "Like")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(liked ? MatchaTokens.Colors.danger : MatchaTokens.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        liked
                            ? MatchaTokens.Colors.danger.opacity(0.1)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    )
                    .liquidGlass(cornerRadius: MatchaTokens.Radius.button)
                }

                // Message button
                Button(action: { showMessageAlert = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.body.weight(.semibold))
                        Text("Message")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(MatchaTokens.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.medium)
            .background(MatchaTokens.Colors.background)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(MatchaTokens.Colors.textSecondary)
            .tracking(1.2)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }

    // MARK: - UGC

    private func loadUGCPosts() async {
        guard profile.role == .business else { return }
        do {
            let dtos: [UGCPostDTO] = try await NetworkService.shared.request(
                .GET, path: "/profiles/\(profile.serverUserId)/ugc"
            )
            ugcPosts = dtos.map { $0.toDomain() }
        } catch {
            ugcPosts = []
        }
    }
}
