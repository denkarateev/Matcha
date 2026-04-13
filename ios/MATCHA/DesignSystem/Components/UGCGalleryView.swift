import SwiftUI

// MARK: - UGCGalleryView

/// Auto-populated gallery from Content Proof submissions by bloggers.
/// Business can hide individual posts but cannot add their own.
struct UGCGalleryView: View {
    let posts: [UGCPost]
    let isOwner: Bool
    var onHidePost: ((UGCPost) -> Void)?

    private var visiblePosts: [UGCPost] {
        isOwner ? posts : posts.filter { !$0.isHidden }
    }

    var body: some View {
        if visiblePosts.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                sectionHeader

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(visiblePosts) { post in
                            ugcCard(post)
                        }
                    }
                    .padding(.horizontal, MatchaTokens.Spacing.large)
                }
            }
        )
    }

    // MARK: - Header

    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Text("UGC GALLERY")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)

            Text("\(visiblePosts.count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(MatchaTokens.Colors.accent.opacity(0.15), in: Capsule())

            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
    }

    // MARK: - Card

    private func ugcCard(_ post: UGCPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                Group {
                    if let url = post.thumbnailURL ?? post.screenshotURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                placeholderThumbnail
                            }
                        }
                    } else {
                        placeholderThumbnail
                    }
                }
                .frame(width: 140, height: 175)
                .clipped()

                // Hidden badge (owner only)
                if isOwner && post.isHidden {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(6)
                }

                // Platform icon
                platformBadge(for: post)
            }

            // Info footer
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // Blogger avatar
                    if let avatarURL = post.bloggerPhotoURL {
                        AsyncImage(url: avatarURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Circle().fill(MatchaTokens.Colors.elevated)
                            }
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }

                    Text(post.bloggerName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(1)
                }

                Text(post.displayDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(width: 140, alignment: .leading)
        }
        .background(MatchaTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
        )
        .opacity(post.isHidden ? 0.5 : 1)
        .contextMenu {
            if isOwner {
                Button(role: post.isHidden ? nil : .destructive) {
                    onHidePost?(post)
                } label: {
                    Label(
                        post.isHidden ? "Show in Gallery" : "Hide from Gallery",
                        systemImage: post.isHidden ? "eye" : "eye.slash"
                    )
                }
            }

            if let url = URL(string: post.postURL) {
                Link(destination: url) {
                    Label("Open Post", systemImage: "arrow.up.right.square")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("UGC post by \(post.bloggerName)")
    }

    // MARK: - Helpers

    private var placeholderThumbnail: some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Image(systemName: "photo.on.rectangle.angled")
                .font(.title3)
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
        }
    }

    @ViewBuilder
    private func platformBadge(for post: UGCPost) -> some View {
        let isInstagram = post.postURL.contains("instagram.com")
        let isTikTok = post.postURL.contains("tiktok.com")

        if isInstagram || isTikTok {
            Image(systemName: isInstagram ? "camera.fill" : "play.rectangle.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .padding(5)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}
