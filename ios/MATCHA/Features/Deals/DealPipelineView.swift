import SwiftUI

// MARK: - DealPipelineView
/// Reusable deal progress pipeline showing stages: Draft -> Confirmed -> Visited -> Reviewed.
/// `compact` = true renders a mini version for in-message deal cards.

struct DealPipelineView: View {
    let deal: Deal
    let compact: Bool
    var onAdvanceStage: (() -> Void)? = nil
    var onTapDetails: (() -> Void)? = nil
    var onAcceptDraft: (() -> Void)? = nil
    var onDeclineDraft: (() -> Void)? = nil
    var onReportNoShow: (() -> Void)? = nil
    var onCancelDeal: (() -> Void)? = nil
    var isPerformingAction = false

    // The four linear stages displayed in the pipeline
    private static let stages: [DealStatus] = [.draft, .confirmed, .visited, .reviewed]

    private var circleSize: CGFloat { compact ? 16 : 24 }
    private var lineHeight: CGFloat { compact ? 2 : 3 }
    private var fontSize: Font { compact ? .system(size: 9, weight: .medium) : .system(size: 10, weight: .semibold) }
    private var checkmarkFont: Font { compact ? .system(size: 8, weight: .bold) : .system(size: 11, weight: .bold) }
    private var shortPartnerName: String {
        deal.partnerName.components(separatedBy: " ").first ?? deal.partnerName
    }

    private var currentIndex: Int {
        switch deal.status {
        case .cancelled:
            return 0
        case .noShow:
            return 2
        default:
            return Self.stages.firstIndex(of: deal.status) ?? -1
        }
    }

    var body: some View {
        Group {
            if compact {
                compactLayout
            } else {
                fullBanner
            }
        }
        .accessibilityIdentifier("deal-pipeline")
    }

    // MARK: - Full Banner (under chat header)

    private var fullBanner: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "wallet.pass.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text("Active Deal")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .tracking(0.6)
                }

                Spacer()

                if let onTapDetails {
                    Button(action: onTapDetails) {
                        Text("Details >")
                            .font(.caption.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.top, 12)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 10) {
                pipelineRow
                stageLabelsRow
                dealInfoRow
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MatchaTokens.Colors.surface.opacity(0.96),
                                MatchaTokens.Colors.elevated.opacity(0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.outline.opacity(0.75), lineWidth: 1)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onTapGesture {
                onTapDetails?()
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)

            if !compact {
                actionFooter
                    .padding(.horizontal, MatchaTokens.Spacing.medium)
                    .padding(.top, 10)
            }
        }
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    MatchaTokens.Colors.surface,
                    MatchaTokens.Colors.surface.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Divider().background(MatchaTokens.Colors.outline)
        }
    }

    // MARK: - Compact Layout (in-message card)

    private var compactLayout: some View {
        VStack(spacing: 4) {
            pipelineRow
            compactLabelsRow
        }
    }

    // MARK: - Pipeline Row (circles + lines)

    private var pipelineRow: some View {
        GeometryReader { geo in
            let stages = Self.stages
            let count = CGFloat(stages.count)
            let totalWidth = geo.size.width
            let spacing = (totalWidth - circleSize * count) / (count - 1)

            ZStack(alignment: .leading) {
                // Draw connecting lines first (behind circles)
                ForEach(0..<stages.count - 1, id: \.self) { i in
                    let xStart = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2
                    let xEnd = circleSize * CGFloat(i + 1) + spacing * CGFloat(i + 1) + circleSize / 2
                    let isCompleted = i < currentIndex

                    Rectangle()
                        .fill(isCompleted ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline)
                        .frame(width: xEnd - xStart, height: lineHeight)
                        .position(x: (xStart + xEnd) / 2, y: circleSize / 2)
                }

                // Draw circles on top
                ForEach(0..<stages.count, id: \.self) { i in
                    let xPos = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2

                    stageCircle(index: i)
                        .position(x: xPos, y: circleSize / 2)
                }
            }
        }
        .frame(height: circleSize)
    }

    // MARK: - Stage Circle

    @ViewBuilder
    private func stageCircle(index: Int) -> some View {
        let isCompleted = index < currentIndex
        let isCurrent = index == currentIndex
        // let isFuture = index > currentIndex  // not needed explicitly

        ZStack {
            if isCompleted {
                // Solid green circle with white checkmark
                Circle()
                    .fill(MatchaTokens.Colors.accent)
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: "checkmark")
                    .font(checkmarkFont)
                    .foregroundStyle(MatchaTokens.Colors.background)
            } else if isCurrent {
                // Green bordered circle with glow + small dot inside
                Circle()
                    .fill(MatchaTokens.Colors.background)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle()
                            .strokeBorder(MatchaTokens.Colors.accent, lineWidth: compact ? 1.5 : 2)
                    )
                    .shadow(color: MatchaTokens.Colors.accent.opacity(0.6), radius: compact ? 4 : 8)

                Circle()
                    .fill(MatchaTokens.Colors.accent)
                    .frame(width: circleSize * 0.35, height: circleSize * 0.35)
            } else {
                // Future: gray circle
                Circle()
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle()
                            .strokeBorder(MatchaTokens.Colors.outline, lineWidth: compact ? 1 : 1.5)
                    )
            }
        }
    }

    // MARK: - Stage Labels (full)

    private var stageLabelsRow: some View {
        GeometryReader { geo in
            let stages = Self.stages
            let count = CGFloat(stages.count)
            let totalWidth = geo.size.width
            let spacing = (totalWidth - circleSize * count) / (count - 1)

            ZStack(alignment: .leading) {
                ForEach(0..<stages.count, id: \.self) { i in
                    let xPos = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2
                    let isCompleted = i < currentIndex
                    let isCurrent = i == currentIndex

                    Text(stages[i].title)
                        .font(fontSize)
                        .foregroundStyle(
                            isCompleted || isCurrent
                                ? MatchaTokens.Colors.accent
                                : MatchaTokens.Colors.textSecondary.opacity(0.5)
                        )
                        .position(x: xPos, y: 6)
                }
            }
        }
        .frame(height: 14)
    }

    // MARK: - Compact Labels

    private var compactLabelsRow: some View {
        GeometryReader { geo in
            let stages = Self.stages
            let count = CGFloat(stages.count)
            let totalWidth = geo.size.width
            let spacing = (totalWidth - circleSize * count) / (count - 1)

            ZStack(alignment: .leading) {
                ForEach(0..<stages.count, id: \.self) { i in
                    let xPos = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2
                    let shortLabel: String = {
                        switch stages[i] {
                        case .draft: return "D"
                        case .confirmed: return "C"
                        case .visited: return "V"
                        case .reviewed: return "R"
                        default: return ""
                        }
                    }()

                    Text(shortLabel)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                        .position(x: xPos, y: 4)
                }
            }
        }
        .frame(height: 10)
    }

    // MARK: - Deal Info Row

    private var dealInfoRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                if let scheduled = deal.scheduledDate,
                   !deal.scheduledDateText.isEmpty,
                   scheduled > Date() {
                    metaChip(icon: "calendar.badge.clock", text: deal.scheduledDateText)
                }

                if let locationName = deal.locationName, !locationName.isEmpty {
                    metaChip(icon: "mappin.and.ellipse", text: locationName)
                }

                Spacer(minLength: 0)
            }

            if !deal.youOffer.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                    Text(deal.youOffer)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            } else if !deal.title.isEmpty {
                Text(deal.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
    }

    private func metaChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Action Footer

    @ViewBuilder
    private var actionFooter: some View {
        switch deal.status {
        case .draft where !deal.isMine:
            HStack(spacing: 10) {
                footerButton(
                    title: "Decline",
                    icon: "xmark",
                    background: MatchaTokens.Colors.elevated,
                    foreground: MatchaTokens.Colors.textPrimary,
                    borderColor: MatchaTokens.Colors.outline,
                    fillsWidth: false,
                    action: onDeclineDraft
                )

                footerButton(
                    title: "Confirm",
                    icon: "checkmark",
                    background: MatchaTokens.Colors.accent,
                    foreground: MatchaTokens.Colors.background,
                    borderColor: MatchaTokens.Colors.accent.opacity(0.45),
                    fillsWidth: true,
                    action: onAcceptDraft
                )
            }
        case .draft:
            footerStatus(
                text: "Proposal sent. \(shortPartnerName) has to confirm it before the deal moves forward.",
                icon: "hourglass",
                tint: MatchaTokens.Colors.warning
            )
            cancelDealButton
        case .confirmed:
            if deal.myCheckInDone && !deal.partnerCheckInDone {
                footerStatus(
                    text: "You checked in. Waiting for \(shortPartnerName) to confirm.",
                    icon: "clock.badge.checkmark",
                    tint: MatchaTokens.Colors.warning
                )
                if let onReportNoShow {
                    Button(action: onReportNoShow) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption.weight(.bold))
                            Text("Report No-Show")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(MatchaTokens.Colors.danger, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                cancelDealButton
            } else {
                footerButton(
                    title: deal.partnerCheckInDone ? "Confirm Visit" : "Check In",
                    icon: "location.fill",
                    background: MatchaTokens.Colors.accent,
                    foreground: MatchaTokens.Colors.background,
                    borderColor: MatchaTokens.Colors.accent.opacity(0.45),
                    fillsWidth: true,
                    action: onAdvanceStage
                )
            }
        case .visited:
            if deal.myReview == nil {
                footerButton(
                    title: "Leave Review",
                    icon: "star.fill",
                    background: MatchaTokens.Colors.accent,
                    foreground: MatchaTokens.Colors.background,
                    borderColor: MatchaTokens.Colors.accent.opacity(0.45),
                    fillsWidth: true,
                    action: onAdvanceStage
                )
            } else if deal.reviewsReady {
                footerStatus(
                    text: "Reviews submitted. Deal completed.",
                    icon: "checkmark.seal.fill",
                    tint: MatchaTokens.Colors.success
                )
            } else {
                footerStatus(
                    text: "Your review is in. Waiting for \(shortPartnerName).",
                    icon: "clock.arrow.trianglehead.2.counterclockwise.rotate.90",
                    tint: MatchaTokens.Colors.warning
                )
            }
        case .reviewed:
            footerStatus(
                text: "Reviews submitted. Deal completed.",
                icon: "checkmark.seal.fill",
                tint: MatchaTokens.Colors.success
            )
        case .cancelled:
            footerStatus(
                text: "This deal was cancelled.",
                icon: "xmark.circle.fill",
                tint: MatchaTokens.Colors.danger
            )
        case .noShow:
            if deal.myReview == nil {
                footerButton(
                    title: "Leave Review",
                    icon: "star.fill",
                    background: MatchaTokens.Colors.warning,
                    foreground: MatchaTokens.Colors.background,
                    borderColor: MatchaTokens.Colors.warning.opacity(0.4),
                    fillsWidth: true,
                    action: onAdvanceStage
                )
            } else {
                footerStatus(
                    text: "No-show recorded. Waiting for final review.",
                    icon: "exclamationmark.triangle.fill",
                    tint: MatchaTokens.Colors.warning
                )
            }
        }
    }

    private func footerButton(
        title: String,
        icon: String,
        background: Color,
        foreground: Color,
        borderColor: Color,
        fillsWidth: Bool,
        action: (() -> Void)?
    ) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action?()
        } label: {
            HStack(spacing: 6) {
                if isPerformingAction {
                    ProgressView()
                        .tint(foreground)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                }
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(background, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil || isPerformingAction)
        .opacity(action == nil ? 0.55 : 1)
    }

    @ViewBuilder
    private var cancelDealButton: some View {
        if let onCancelDeal, deal.status == .draft || deal.status == .confirmed {
            Button(action: onCancelDeal) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle")
                        .font(.caption.weight(.bold))
                    Text("Cancel Deal")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(MatchaTokens.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private func footerStatus(text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MatchaTokens.Colors.elevated.opacity(0.8), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(MatchaTokens.Colors.outline.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Full Banner - Confirmed") {
    VStack(spacing: 0) {
        DealPipelineView(
            deal: Deal(
                id: UUID(),
                partnerName: "The Lawn Canggu",
                title: "Surf lesson + content",
                scheduledDateText: "Apr 5, 08:00",
                scheduledDate: nil,
                locationName: "Canggu Beach",
                status: .confirmed,
                progressNote: "Both agreed",
                canRepeat: false,
                contentProofStatus: nil,
                dealType: .barter,
                youOffer: "2 Reels + 3 Stories",
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
            compact: false,
            onAdvanceStage: {},
            onTapDetails: {}
        )
        Spacer()
    }
    .background(MatchaTokens.Colors.background)
}

#Preview("Compact - Visited") {
    DealPipelineView(
        deal: Deal(
            id: UUID(),
            partnerName: "COMO Uma",
            title: "Villa tour",
            scheduledDateText: "Apr 7, 10:00",
            scheduledDate: nil,
            locationName: "COMO Uma Canggu",
            status: .visited,
            progressNote: "",
            canRepeat: false,
            contentProofStatus: nil,
            dealType: .paid,
            youOffer: "1 Reel",
            youReceive: "$250",
            guests: .solo,
            contentDeadline: nil,
            checkIn: DealCheckIn(),
            myRole: .blogger,
            bloggerReview: nil,
            businessReview: nil,
            contentProof: nil,
            isMine: true
        ),
        compact: true
    )
    .padding()
    .background(MatchaTokens.Colors.surface)
}
