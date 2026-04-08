import SwiftUI

// MARK: - ShareDealCard

/// Generates a shareable card image after a finished deal.
/// Dark background with MATCHA branding, both partner photos, and deal type badge.
struct ShareDealCard: View {
    let deal: Deal
    let partnerPhotoURL: URL?
    let myPhotoURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Top branding
            HStack {
                Text("MATCHA")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .tracking(2)
                Spacer()
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Partner photos side by side
            HStack(spacing: -16) {
                shareCardAvatar(url: myPhotoURL, fallbackIcon: "person.fill")
                shareCardAvatar(url: partnerPhotoURL, fallbackIcon: "person.fill")
            }
            .padding(.bottom, 20)

            // Headline
            Text("Brewed with MATCHA \u{2615}")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 6)

            // Deal info
            Text("Collab with \(deal.partnerName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 12)

            // Deal type badge
            Text(deal.dealType.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(dealBadgeColor, in: Capsule())
                .padding(.bottom, 20)

            // Divider
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 20)

            // Bottom link
            HStack {
                Spacer()
                Text("matcha.app/join")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.8))
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x0E1410),
                            Color(hex: 0x0A0E0C),
                            Color(hex: 0x080A09)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(
                            MatchaTokens.Colors.accent.opacity(0.15),
                            lineWidth: 1
                        )
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Helpers

    private var dealBadgeColor: Color {
        switch deal.dealType {
        case .barter: MatchaTokens.Colors.accent
        case .paid: MatchaTokens.Colors.warning
        }
    }

    private func shareCardAvatar(url: URL?, fallbackIcon: String) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        avatarPlaceholder(icon: fallbackIcon)
                    }
                }
            } else {
                avatarPlaceholder(icon: fallbackIcon)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color(hex: 0x0E1410), lineWidth: 3))
        .overlay(Circle().strokeBorder(MatchaTokens.Colors.accent.opacity(0.3), lineWidth: 1))
    }

    private func avatarPlaceholder(icon: String) -> some View {
        ZStack {
            Circle()
                .fill(MatchaTokens.Colors.elevated)
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.4))
        }
    }

    // MARK: - Render to UIImage

    /// Renders this card view to a UIImage for sharing via UIActivityViewController.
    @MainActor
    func renderToImage() -> UIImage {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 320, height: nil)
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - ShareDealCardSheet

/// Wraps ShareDealCard with a share button for presentation in a sheet.
struct ShareDealCardSheet: View {
    let deal: Deal
    let partnerPhotoURL: URL?
    let myPhotoURL: URL?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("Share your collab")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

            ShareDealCard(
                deal: deal,
                partnerPhotoURL: partnerPhotoURL,
                myPhotoURL: myPhotoURL
            )

            Button {
                let card = ShareDealCard(
                    deal: deal,
                    partnerPhotoURL: partnerPhotoURL,
                    myPhotoURL: myPhotoURL
                )
                let image = card.renderToImage()
                let shareText = "Just brewed a collab on MATCHA \u{2615}\nJoin: matcha.app/join"
                let activityVC = UIActivityViewController(
                    activityItems: [image, shareText],
                    applicationActivities: nil
                )
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Share Card")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview {
    ShareDealCard(
        deal: Deal(
            id: UUID(),
            partnerName: "Bali Sunset Cafe",
            title: "Instagram Reel",
            scheduledDateText: "Apr 15, 2026",
            scheduledDate: nil,
            locationName: "Canggu",
            status: .reviewed,
            progressNote: "Completed",
            canRepeat: false,
            contentProofStatus: nil,
            dealType: .barter,
            youOffer: "1 Reel + Stories",
            youReceive: "Dinner for 2",
            guests: .solo,
            contentDeadline: nil,
            checkIn: DealCheckIn(),
            myRole: .blogger,
            bloggerReview: nil,
            businessReview: nil,
            contentProof: nil,
            isMine: true
        ),
        partnerPhotoURL: nil,
        myPhotoURL: nil
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
