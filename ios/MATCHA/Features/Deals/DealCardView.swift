import SwiftUI

// MARK: - DealCardView
// Shown inline in chat message stream.

struct DealCardView: View {
    let deal: Deal
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    var onViewDetail: (() -> Void)?

    private var statusColor: Color {
        switch deal.status {
        case .draft:      return MatchaTokens.Colors.textSecondary
        case .confirmed:  return MatchaTokens.Colors.accent
        case .visited:    return MatchaTokens.Colors.baliBlue
        case .reviewed:   return MatchaTokens.Colors.success
        case .cancelled:  return MatchaTokens.Colors.danger
        case .noShow:     return MatchaTokens.Colors.warning
        }
    }

    private var statusIcon: String {
        switch deal.status {
        case .draft:      return "doc.text.fill"
        case .confirmed:  return "checkmark.circle.fill"
        case .visited:    return "location.circle.fill"
        case .reviewed:   return "star.circle.fill"
        case .cancelled:  return "xmark.circle.fill"
        case .noShow:     return "exclamationmark.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                topBadge
                contentArea
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .onTapGesture {
                onViewDetail?()
            }

            if deal.status == .draft && !deal.isMine && (onAccept != nil || onDecline != nil) {
                actionButtons
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(MatchaTokens.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(statusColor.opacity(0.25), lineWidth: 1)
                )
        )
        .matchaShadow(MatchaTokens.Shadow.level1)
        .frame(maxWidth: 320)
        .accessibilityIdentifier("deal-card-\(deal.id.uuidString)")
    }

    // MARK: - Top Badge Row

    private var topBadge: some View {
        HStack(spacing: 8) {
            // Handshake icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(statusColor.opacity(0.14))
                    .frame(width: 30, height: 30)
                Image(systemName: "person.2.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(deal.dealType.title + " Deal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .tracking(0.4)
                if !deal.scheduledDateText.isEmpty {
                    Text(deal.scheduledDateText)
                        .font(.caption2)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }

            Spacer()

            // Status pill
            Text(deal.status.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(statusColor)
                .tracking(0.8)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(statusColor.opacity(0.3), lineWidth: 0.5))
                .accessibilityIdentifier("deal-status-badge")
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, MatchaTokens.Spacing.small)
    }

    // MARK: - Content

    private var contentArea: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .background(MatchaTokens.Colors.outline)

            // Brief description
            if !deal.title.isEmpty {
                Text(deal.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .padding(.horizontal, 14)
            }

            // Meta row: date + location + deliverables
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    if !deal.scheduledDateText.isEmpty {
                        metaChip(icon: "calendar", text: deal.scheduledDateText)
                    }
                    if let locationName = deal.locationName, !locationName.isEmpty {
                        metaChip(icon: "mappin", text: locationName)
                    }
                }

                if !deal.youOffer.isEmpty {
                    metaChip(icon: "shippingbox.fill", text: deal.youOffer)
                }
            }
            .padding(.horizontal, 14)

            // Mini pipeline
            DealPipelineView(deal: deal, compact: true)
                .padding(.horizontal, 14)
                .padding(.top, 4)

            Spacer().frame(height: deal.status == .draft && !deal.isMine && (onAccept != nil || onDecline != nil) ? 4 : 10)
        }
    }

    private func dealRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Action Buttons (Draft, incoming deal)

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MatchaTokens.Colors.outline)

            HStack(spacing: 0) {
                Button(action: { onDecline?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                        Text("Decline")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(MatchaTokens.Colors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .accessibilityIdentifier("deal-decline-button")

                Divider()
                    .frame(height: 44)
                    .background(MatchaTokens.Colors.outline)

                Button(action: { onAccept?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .accessibilityIdentifier("deal-accept-button")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        DealCardView(
            deal: Deal(
                id: UUID(),
                partnerName: "The Lawn Canggu",
                title: "1 Reel + 3 Stories, tagged within 48h",
                scheduledDateText: "Apr 5, 19:30",
                scheduledDate: nil,
                locationName: "Canggu Beach",
                status: .draft,
                progressNote: "Awaiting acceptance",
                canRepeat: false,
                contentProofStatus: nil,
                dealType: .barter,
                youOffer: "1 Reel + 3 Stories, tagged within 48h",
                youReceive: "Dinner for 2 at sunset table",
                guests: .plusOne,
                contentDeadline: nil,
                checkIn: DealCheckIn(),
                myRole: .blogger,
                bloggerReview: nil,
                businessReview: nil,
                contentProof: nil,
                isMine: false
            ),
            onAccept: {},
            onDecline: {}
        )

        DealCardView(
            deal: Deal(
                id: UUID(),
                partnerName: "COMO Uma Canggu",
                title: "Villa tour content",
                scheduledDateText: "Apr 7, 10:00",
                scheduledDate: nil,
                locationName: "COMO Uma Canggu",
                status: .confirmed,
                progressNote: "Both agreed",
                canRepeat: false,
                contentProofStatus: nil,
                dealType: .paid,
                youOffer: "1 hero reel + 5 photos",
                youReceive: "2-night stay + $250",
                guests: .solo,
                contentDeadline: nil,
                checkIn: DealCheckIn(),
                myRole: .blogger,
                bloggerReview: nil,
                businessReview: nil,
                contentProof: nil,
                isMine: true
            )
        )
    }
    .padding()
    .background(MatchaTokens.Colors.background)
}
