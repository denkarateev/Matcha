import SwiftUI

// MARK: - DealCardView
// Hero-style deal card shown inline in chat message stream.
// Design: полноразмерное hero пространство сверху (gradient + partner avatar
// + status pill top-right + title/date overlay), ниже — vertical timeline
// пайплайна сделки с датами. Accept/Decline действия для входящих drafts.

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

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                statusColor.opacity(0.55),
                statusColor.opacity(0.18),
                Color.black.opacity(0.55),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var partnerInitials: String {
        let parts = deal.partnerName.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                bodySection
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onTapGesture { onViewDetail?() }

            if deal.status == .draft && !deal.isMine && (onAccept != nil || onDecline != nil) {
                actionButtons
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(MatchaTokens.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .matchaShadow(MatchaTokens.Shadow.level1)
        .frame(maxWidth: 340)
        .accessibilityIdentifier("deal-card-\(deal.id.uuidString)")
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .top) {
            heroGradient
                .frame(height: 140)
                .overlay {
                    // Decorative rings
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .offset(x: 120, y: -40)
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        .frame(width: 140, height: 140)
                        .offset(x: -70, y: 60)
                }

            VStack(spacing: 0) {
                // Top row: avatar + status pill
                HStack(alignment: .top, spacing: 12) {
                    avatarCircle

                    VStack(alignment: .leading, spacing: 2) {
                        Text(deal.partnerName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(deal.dealType.title.uppercased() + " DEAL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.75))
                            .tracking(0.8)
                    }
                    Spacer()
                    statusPill
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)

                Spacer()

                // Bottom: title + meta
                VStack(alignment: .leading, spacing: 6) {
                    if !deal.title.isEmpty {
                        Text(deal.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(spacing: 10) {
                        if !deal.scheduledDateText.isEmpty {
                            heroMeta(icon: "calendar", text: deal.scheduledDateText)
                        }
                        if let loc = deal.locationName, !loc.isEmpty {
                            heroMeta(icon: "mappin", text: loc)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(height: 140)
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 1))
            Text(partnerInitials)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(deal.status.title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .tracking(0.6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.black.opacity(0.45), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
        .accessibilityIdentifier("deal-status-badge")
    }

    private func heroMeta(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    // MARK: - Body (vertical timeline + exchange)

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Vertical deal timeline
            VerticalDealTimeline(deal: deal)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            if !deal.youOffer.isEmpty || !deal.youReceive.isEmpty {
                Divider().background(MatchaTokens.Colors.outline)

                VStack(alignment: .leading, spacing: 8) {
                    if !deal.youOffer.isEmpty {
                        exchangeRow(icon: "arrow.up.right", iconColor: MatchaTokens.Colors.accent, label: "You give", text: deal.youOffer)
                    }
                    if !deal.youReceive.isEmpty {
                        exchangeRow(icon: "arrow.down.left", iconColor: MatchaTokens.Colors.baliBlue, label: "You get", text: deal.youReceive)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private func exchangeRow(icon: String, iconColor: Color, label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 24, height: 24)
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .tracking(0.6)
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Action Buttons (Draft, incoming)

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Divider().background(MatchaTokens.Colors.outline)
            HStack(spacing: 0) {
                Button(action: { onDecline?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark").font(.caption.weight(.bold))
                        Text("Decline").font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(MatchaTokens.Colors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                }
                .accessibilityIdentifier("deal-decline-button")

                Divider().frame(height: 44).background(MatchaTokens.Colors.outline)

                Button(action: { onAccept?() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark").font(.caption.weight(.bold))
                        Text("Accept").font(.subheadline.weight(.semibold))
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

// MARK: - VerticalDealTimeline
// Stepped vertical timeline (draft → confirmed → visited → reviewed) с датами
// и connector-line. Cancelled и no-show отображаются как terminal состояние
// на соответствующем шаге.

struct VerticalDealTimeline: View {
    let deal: Deal

    private static let steps: [DealStatus] = [.draft, .confirmed, .visited, .reviewed]

    private var currentStepIndex: Int {
        switch deal.status {
        case .cancelled: return -1
        case .noShow: return 1
        default: return Self.steps.firstIndex(of: deal.status) ?? -1
        }
    }

    private var isTerminal: Bool {
        deal.status == .cancelled || deal.status == .noShow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { idx, step in
                timelineRow(
                    step: step,
                    index: idx,
                    isLast: idx == Self.steps.count - 1
                )
            }

            if isTerminal {
                terminalBanner
            }
        }
    }

    private func timelineRow(step: DealStatus, index: Int, isLast: Bool) -> some View {
        let state: StepState = {
            if isTerminal { return .upcoming }
            if index < currentStepIndex { return .done }
            if index == currentStepIndex { return .current }
            return .upcoming
        }()

        return HStack(alignment: .top, spacing: 12) {
            // Dot + connector
            VStack(spacing: 0) {
                dot(state: state)
                if !isLast {
                    Rectangle()
                        .fill(state == .done ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline.opacity(0.5))
                        .frame(width: 2)
                        .frame(minHeight: 28)
                }
            }
            .frame(width: 20)

            // Step content
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 13, weight: state == .current ? .bold : .semibold))
                    .foregroundStyle(state.textColor)

                if let meta = metaFor(step: step, state: state) {
                    Text(meta)
                        .font(.system(size: 11))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .padding(.top, 1)
            .padding(.bottom, isLast ? 0 : 14)

            Spacer(minLength: 0)
        }
    }

    private func dot(state: StepState) -> some View {
        ZStack {
            Circle()
                .fill(state.fillColor)
                .frame(width: 20, height: 20)

            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.background)
            } else if state == .current {
                Circle()
                    .stroke(MatchaTokens.Colors.accent, lineWidth: 2)
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(MatchaTokens.Colors.accent)
                    .frame(width: 8, height: 8)
                    .shadow(color: MatchaTokens.Colors.accent.opacity(0.6), radius: 4)
            } else {
                Circle()
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1.5)
                    .frame(width: 20, height: 20)
            }
        }
    }

    private func metaFor(step: DealStatus, state: StepState) -> String? {
        switch step {
        case .draft:
            return state == .current ? "Awaiting partner acceptance" : nil
        case .confirmed:
            if state == .current || state == .done {
                return deal.scheduledDateText.isEmpty ? "Both parties agreed" : deal.scheduledDateText
            }
            return nil
        case .visited:
            if state == .current {
                return "Confirm visit to continue"
            }
            if state == .done, let loc = deal.locationName {
                return loc
            }
            return nil
        case .reviewed:
            if state == .done { return "Reviews exchanged" }
            if state == .current { return "Leave review" }
            return nil
        default: return nil
        }
    }

    private var terminalBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: deal.status == .cancelled ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(deal.status == .cancelled ? MatchaTokens.Colors.danger : MatchaTokens.Colors.warning)
            Text(deal.status == .cancelled ? "Deal cancelled" : "Partner didn't show")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .padding(.top, 6)
    }

    private enum StepState {
        case done, current, upcoming

        var fillColor: Color {
            switch self {
            case .done: return MatchaTokens.Colors.accent
            case .current: return .clear
            case .upcoming: return .clear
            }
        }

        var textColor: Color {
            switch self {
            case .done, .current: return MatchaTokens.Colors.textPrimary
            case .upcoming: return MatchaTokens.Colors.textSecondary.opacity(0.7)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
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
    }
    .background(MatchaTokens.Colors.background)
}
