import SwiftUI

// MARK: - OfferCardData

struct OfferCardData: Identifiable {
    let id: String
    let businessLogoURL: URL?
    let businessName: String
    let offerTitle: String
    let offerType: String         // e.g. "Food Review", "Story Post"
    let slotsLeft: Int
    let expiresInDays: Int
    let respondedCount: Int
    let rewardSummary: String     // e.g. "Free dinner for 2 + ₿ 200K"
    var isHighlighted: Bool = false
    var isUnlimitedSlots: Bool = false
}

// MARK: - OfferCard

struct OfferCard: View {
    let data: OfferCardData
    var onApply: (() -> Void)? = nil
    var onView: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if data.isHighlighted {
                highlightBanner
            }

            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                headerRow
                titleRow
                statsRow
                rewardRow
                Divider().background(MatchaTokens.Colors.outline)
                actionRow
            }
            .padding(MatchaTokens.Spacing.medium)
        }
        .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                .strokeBorder(
                    data.isHighlighted ? MatchaTokens.Colors.accent.opacity(0.5) : MatchaTokens.Colors.outline,
                    lineWidth: 1
                )
        }
        .matchaShadow(MatchaTokens.Shadow.level2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.offerTitle) by \(data.businessName). \(data.rewardSummary). \(data.slotsLeft) slots left.")
    }

    // MARK: - Highlight banner

    private var highlightBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .bold))
            Text("Last Minute")
                .font(MatchaTokens.Typography.caption)
                .fontWeight(.bold)
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MatchaTokens.Spacing.xSmall)
        .background(MatchaTokens.Colors.accent)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: MatchaTokens.Radius.card,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: MatchaTokens.Radius.card
            )
        )
    }

    // MARK: - Header row: logo + business name + type tag

    private var headerRow: some View {
        HStack(spacing: MatchaTokens.Spacing.small) {
            MatchaAvatar(
                url: data.businessLogoURL,
                initials: String(data.businessName.prefix(2)),
                size: .medium
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(data.businessName)
                    .font(MatchaTokens.Typography.headline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(1)

                Text(data.offerType)
                    .font(MatchaTokens.Typography.caption)
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            Spacer()

            urgencyPill
        }
    }

    private var urgencyPill: some View {
        Group {
            if data.expiresInDays <= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text("\(data.expiresInDays)d left")
                        .font(MatchaTokens.Typography.caption)
                }
                .foregroundStyle(MatchaTokens.Colors.danger)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MatchaTokens.Colors.danger.opacity(0.15), in: Capsule())
            } else {
                Text("\(data.expiresInDays) days left")
                    .font(MatchaTokens.Typography.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
        }
    }

    // MARK: - Title row

    private var titleRow: some View {
        Text(data.offerTitle)
            .font(MatchaTokens.Typography.title2)
            .foregroundStyle(MatchaTokens.Colors.textPrimary)
            .lineLimit(2)
    }

    // MARK: - Stats row: slots + respondents

    private var statsRow: some View {
        HStack(spacing: MatchaTokens.Spacing.medium) {
            if data.isUnlimitedSlots {
                statPill(
                    icon: "infinity",
                    value: "No Limit",
                    color: MatchaTokens.Colors.accent
                )
            } else {
                statPill(
                    icon: data.slotsLeft <= 3 ? "flame.fill" : "person.2.fill",
                    value: "\(data.slotsLeft) slots left",
                    color: data.slotsLeft <= 3 ? MatchaTokens.Colors.warning : MatchaTokens.Colors.textSecondary
                )
            }

            statPill(
                icon: "person.badge.plus",
                value: "\(data.respondedCount) applied",
                color: MatchaTokens.Colors.textSecondary
            )
        }
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(value)
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(color)
        }
    }

    // MARK: - Reward row

    private var rewardRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 12))
                .foregroundStyle(MatchaTokens.Colors.accent)
            Text(data.rewardSummary)
                .font(MatchaTokens.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, MatchaTokens.Spacing.small)
        .padding(.vertical, MatchaTokens.Spacing.xSmall)
        .background(MatchaTokens.Colors.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: MatchaTokens.Spacing.small) {
            if let onView {
                Button("View details", action: onView)
                    .buttonStyle(MatchaSecondaryButtonStyle())
                    .accessibilityLabel("View offer details for \(data.offerTitle)")
            }

            if let onApply {
                Button("Apply now", action: onApply)
                    .buttonStyle(MatchaPrimaryButtonStyle())
                    .accessibilityLabel("Apply to \(data.offerTitle)")
            }
        }
    }
}

// MARK: - Preview

#Preview("OfferCard") {
    ScrollView {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            OfferCard(
                data: OfferCardData(
                    id: "1",
                    businessLogoURL: nil,
                    businessName: "Ku De Ta",
                    offerTitle: "Sunset dinner collab for lifestyle influencers",
                    offerType: "Food Review",
                    slotsLeft: 2,
                    expiresInDays: 1,
                    respondedCount: 14,
                    rewardSummary: "Free dinner for 2 + Rp 350K",
                    isHighlighted: true
                ),
                onApply: {},
                onView: {}
            )

            OfferCard(
                data: OfferCardData(
                    id: "2",
                    businessLogoURL: nil,
                    businessName: "Potato Head",
                    offerTitle: "Pool party content shoot — stories + reel",
                    offerType: "Story + Reel",
                    slotsLeft: 5,
                    expiresInDays: 7,
                    respondedCount: 6,
                    rewardSummary: "Entry + drinks for 2 + Rp 500K"
                ),
                onApply: {},
                onView: {}
            )
        }
        .padding(MatchaTokens.Spacing.large)
    }
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
