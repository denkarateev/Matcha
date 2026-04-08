import SwiftUI

// MARK: - DealDetailView

struct DealDetailView: View {
    let repository: any MatchaRepository
    var onDealUpdated: ((Deal) -> Void)? = nil

    @State var deal: Deal
    @Environment(\.dismiss) private var dismiss

    // Sheet state
    @State private var showReviewSheet = false
    @State private var showContentProofSheet = false
    @State private var showRepeatAlert = false
    @State private var showCheckInConfirm = false
    @State private var destructiveAction: DestructiveDealAction?
    @State private var error: NetworkError?
    @State private var isPerformingAction = false

    private var statusColor: Color {
        switch deal.status {
        case .draft:      return MatchaTokens.Colors.textMuted
        case .confirmed:  return MatchaTokens.Colors.baliBlue
        case .visited:    return MatchaTokens.Colors.success
        case .reviewed:   return MatchaTokens.Colors.accent
        case .cancelled:  return MatchaTokens.Colors.danger
        case .noShow:     return MatchaTokens.Colors.warning
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if let error {
                    errorBanner(error)
                }

                // Status badge centered
                statusBadge
                    .padding(.top, 4)

                // Single deal info card
                dealInfoCard

                // Pipeline
                if deal.status == .confirmed || deal.status == .visited || deal.status == .reviewed {
                    pipelineSection
                }

                // Check-in section (confirmed)
                if deal.status == .confirmed {
                    checkInSection
                }

                // Content proof status
                if let proofStatus = deal.contentProofStatus {
                    proofStatusSection(proofStatus)
                }

                // Submitted proof
                if let proof = deal.contentProof {
                    submittedProofSection(proof)
                }

                // Reviews (visited / reviewed)
                if deal.status == .visited || deal.status == .reviewed {
                    reviewsSection
                }

                // Actions
                actionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Deal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }
        }
        .task(id: deal.id) {
            await loadLatestDeal()
        }
        // MARK: Alerts
        .alert(destructiveAction?.title ?? "Deal Action", isPresented: destructiveActionBinding) {
            Button(destructiveAction?.confirmLabel ?? "Confirm", role: .destructive) {
                Task { await performDestructiveAction() }
            }
            Button("Keep", role: .cancel) { destructiveAction = nil }
        } message: {
            Text(destructiveAction?.message(partnerName: deal.partnerName) ?? "")
        }
        .alert("Repeat Deal", isPresented: $showRepeatAlert) {
            Button("Send Request", role: .none) {
                Task {
                    isPerformingAction = true
                    defer { isPerformingAction = false }
                    do {
                        _ = try await repository.repeatDeal(dealId: deal.id.uuidString)
                    } catch let networkError as NetworkError {
                        self.error = networkError
                    } catch {
                        self.error = .networkError(error)
                    }
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Send a new collaboration request to \(deal.partnerName)?")
        }
        .confirmationDialog("Check In", isPresented: $showCheckInConfirm, titleVisibility: .visible) {
            Button("I'm Here / Blogger Arrived") {
                Task { await checkInDeal() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Confirm your presence for the deal with \(deal.partnerName). Both parties must check in within 24 hours.")
        }
        // MARK: Sheets
        .sheet(isPresented: $showReviewSheet) {
            ReviewDealView(deal: deal) { review in
                Task { await submitReview(review) }
            }
        }
        .sheet(isPresented: $showContentProofSheet) {
            ContentProofView(deal: deal) { proof in
                Task {
                    isPerformingAction = true
                    defer { isPerformingAction = false }
                    do {
                        _ = try await repository.submitContentProof(
                            dealId: deal.id.uuidString,
                            postUrl: proof.url,
                            screenshotUrl: proof.screenshotPath
                        )
                    } catch {
                        // Error handling
                    }
                }
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        Text(deal.status.title.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(statusColor)
            .tracking(1.2)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(statusColor.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Deal Info Card (Single)

    private var dealInfoCard: some View {
        VStack(spacing: 0) {
            // Partner row
            HStack(spacing: 12) {
                // Partner initial avatar
                ZStack {
                    Circle()
                        .fill(MatchaTokens.Colors.accent.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text(String(deal.partnerName.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(deal.partnerName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(deal.title)
                        .font(.system(size: 13))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            cardDivider

            // You Offer
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You Offer")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                    Text(deal.youOffer.isEmpty ? deal.title : deal.youOffer)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            cardDivider

            // You Receive
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(MatchaTokens.Colors.baliBlue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You Receive")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                    Text(deal.youReceive.isEmpty ? deal.progressNote : deal.youReceive)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            cardDivider

            // Inline chips row: Type, Guests, Date (optional), Location (optional)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Type chip
                    inlineChip(
                        icon: deal.dealType == .barter ? "arrow.left.arrow.right" : "banknote",
                        text: deal.dealType.title,
                        color: deal.dealType == .barter ? MatchaTokens.Colors.accent : MatchaTokens.Colors.warning
                    )

                    // Guests chip
                    inlineChip(
                        icon: deal.guests == .solo ? "person.fill" : "person.2.fill",
                        text: deal.guests.title,
                        color: MatchaTokens.Colors.textSecondary
                    )

                    // Schedule chip (only if real date exists)
                    if let date = deal.scheduledDate {
                        inlineChip(
                            icon: "calendar",
                            text: formatChipDate(date),
                            color: MatchaTokens.Colors.accent
                        )
                    }

                    // Location chip
                    if let locationName = deal.locationName, !locationName.isEmpty {
                        inlineChip(
                            icon: "mappin",
                            text: locationName,
                            color: MatchaTokens.Colors.baliBlue
                        )
                    }

                    // Content deadline chip
                    if let deadline = deal.contentDeadline {
                        inlineChip(
                            icon: "clock.fill",
                            text: "Due \(formatChipDate(deadline))",
                            color: MatchaTokens.Colors.danger
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
        }
    }

    private func inlineChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MatchaTokens.Colors.glassBorder, in: Capsule())
        .overlay {
            Capsule().strokeBorder(MatchaTokens.Colors.glassHighlight, lineWidth: 0.5)
        }
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(MatchaTokens.Colors.glassBorder)
            .frame(height: 0.5)
            .padding(.leading, 52)
    }

    // MARK: - Pipeline Section

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Pipeline")

            DealPipelineView(deal: deal, compact: true)
            .padding(16)
            .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Check-In Section

    private var checkInSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Check-In")

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    checkInDot(done: deal.myCheckInDone, label: "You")
                    Rectangle()
                        .fill(
                            deal.myCheckInDone && deal.partnerCheckInDone
                                ? MatchaTokens.Colors.accent.opacity(0.4)
                                : MatchaTokens.Colors.glassHighlight
                        )
                        .frame(height: 2)
                    checkInDot(
                        done: deal.partnerCheckInDone,
                        label: deal.partnerName.components(separatedBy: " ").first ?? "Partner"
                    )
                }
                .padding(.horizontal, 16)

                Text(checkInStatusText)
                    .font(.system(size: 12))
                    .foregroundStyle(MatchaTokens.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 14)
            .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
            }
        }
    }

    private var checkInStatusText: String {
        if deal.myCheckInDone && deal.partnerCheckInDone {
            return "Both checked in -- visit confirmed!"
        } else if deal.myCheckInDone {
            return "Waiting for \(deal.partnerName) to check in. 24h window."
        } else if deal.partnerCheckInDone {
            return "\(deal.partnerName) already checked in. Your turn!"
        } else {
            return "Both parties must check in on visit day."
        }
    }

    private func checkInDot(done: Bool, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(done ? MatchaTokens.Colors.accent.opacity(0.15) : MatchaTokens.Colors.glassFill)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                done ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                                lineWidth: 1.5
                            )
                    )
                Image(systemName: done ? "checkmark" : "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(done ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textMuted)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(done ? .white : MatchaTokens.Colors.textMuted)
        }
    }

    // MARK: - Content Proof

    private func proofStatusSection(_ status: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Content Proof")

            HStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.baliBlue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Proof Status")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                    Text(status)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            .padding(16)
            .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
            }
        }
    }

    private func submittedProofSection(_ proof: ContentProof) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Submitted Proof")

            VStack(spacing: 0) {
                if !proof.url.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Content URL")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MatchaTokens.Colors.textMuted)
                            Text(proof.url)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                if proof.screenshotPath != nil {
                    if !proof.url.isEmpty {
                        Rectangle()
                            .fill(MatchaTokens.Colors.glassBorder)
                            .frame(height: 0.5)
                            .padding(.leading, 52)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MatchaTokens.Colors.baliBlue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screenshot")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(MatchaTokens.Colors.textMuted)
                            Text("Submitted")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(MatchaTokens.Colors.success)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
            }
        }
    }

    // MARK: - Reviews Section

    @ViewBuilder
    private var reviewsSection: some View {
        if deal.reviewsReady {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Reviews")

                if let myRev = deal.myReview {
                    reviewCard(review: myRev, label: "Your Review", isOwn: true)
                }
                if let partnerRev = deal.partnerReview {
                    reviewCard(review: partnerRev, label: "\(deal.partnerName)'s Review", isOwn: false)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Reviews")

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                    Text("Reviews will be revealed when both parties submit, or after 7 days.")
                        .font(.system(size: 13))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                }
                .padding(16)
                .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
                }
            }
        }
    }

    private func reviewCard(review: DealReview, label: String, isOwn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= Int(review.average.rounded()) ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundStyle(MatchaTokens.Colors.warning)
                    }
                }
                Text(String(format: "%.1f", review.average))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.warning)
            }

            Rectangle()
                .fill(MatchaTokens.Colors.glassBorder)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                miniReviewCriteria(label: "Punctuality", value: review.punctuality, color: MatchaTokens.Colors.accent)
                miniReviewCriteria(label: "Offer Match", value: review.offerMatch, color: MatchaTokens.Colors.baliBlue)
                miniReviewCriteria(label: "Communication", value: review.communication, color: MatchaTokens.Colors.success)
            }

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 13))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isOwn ? MatchaTokens.Colors.accent.opacity(0.2) : MatchaTokens.Colors.glassBorder,
                    lineWidth: 0.5
                )
        }
    }

    private func miniReviewCriteria(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(MatchaTokens.Colors.outline, lineWidth: 2)
                    .frame(width: 30, height: 30)
                Text("\(value)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MatchaTokens.Colors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 10) {
            if deal.status == .draft && deal.isMine {
                waitingOnPartnerCard
            }

            // DRAFT: Accept or Decline (incoming deal)
            if deal.status == .draft && !deal.isMine {
                accentButton(title: "Accept Deal", icon: "checkmark.circle.fill") {
                    Task { await acceptDeal() }
                }
                dangerOutlineButton(title: "Decline Deal", icon: "xmark.circle") {
                    destructiveAction = .decline
                }
            }

            // CONFIRMED: Check-in on visit day
            if deal.status == .confirmed && !deal.myCheckInDone {
                accentButton(title: "Check In", icon: "location.fill") {
                    showCheckInConfirm = true
                }
            }

            if deal.status == .confirmed && deal.myCheckInDone && !deal.partnerCheckInDone {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(MatchaTokens.Colors.textMuted)
                        .scaleEffect(0.9)
                    Text("Waiting for \(deal.partnerName) to check in...")
                        .font(.system(size: 14))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
                }
            }

            // VISITED: Content Proof (blogger only) + Leave Review
            if deal.status == .visited {
                if deal.myRole == .blogger && deal.contentProof == nil {
                    accentButton(title: "Submit Content Proof", icon: "photo.badge.checkmark.fill") {
                        showContentProofSheet = true
                    }
                }

                if deal.myReview == nil {
                    outlineButton(title: "Leave Review", icon: "star.fill") {
                        showReviewSheet = true
                    }
                }
            }

            // REVIEWED: Leave review if not yet submitted
            if deal.status == .reviewed && deal.myReview == nil {
                accentButton(title: "Leave Review", icon: "star.fill") {
                    showReviewSheet = true
                }
            }

            // CANCEL button (Draft or Confirmed only)
            if (deal.status == .draft && deal.isMine) || deal.status == .confirmed {
                dangerOutlineButton(title: "Cancel Deal", icon: "xmark.circle") {
                    destructiveAction = .cancel
                }
            }

            // REPEAT COLLAB (Reviewed + canRepeat)
            if deal.canRepeat {
                outlineButton(title: "Repeat Collab", icon: "arrow.trianglehead.2.counterclockwise.rotate.90") {
                    showRepeatAlert = true
                }
            }
        }
        .disabled(isPerformingAction)
        .opacity(isPerformingAction ? 0.7 : 1)
    }

    private var waitingOnPartnerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text("Waiting for \(deal.partnerName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("You sent this proposal. The other side has to confirm it first.")
                    .font(.system(size: 12))
                    .foregroundStyle(MatchaTokens.Colors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(MatchaTokens.Colors.warning.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.warning.opacity(0.25), lineWidth: 0.5)
        }
    }

    // MARK: - Button Styles

    private func accentButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(Color(hex: 0x050505))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isPerformingAction)
    }

    private func outlineButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MatchaTokens.Colors.glassFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 0.5)
            }
        }
        .disabled(isPerformingAction)
    }

    private func dangerOutlineButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(MatchaTokens.Colors.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(MatchaTokens.Colors.danger.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.danger.opacity(0.25), lineWidth: 0.5)
            }
        }
        .disabled(isPerformingAction)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(MatchaTokens.Colors.textMuted)
            .tracking(1.2)
    }

    private func formatChipDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date)
    }

    private var destructiveActionBinding: Binding<Bool> {
        Binding(
            get: { destructiveAction != nil },
            set: { if !$0 { destructiveAction = nil } }
        )
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 14, weight: .medium))
            Text(error.errorDescription ?? "Something went wrong")
                .font(.system(size: 13))
                .lineLimit(3)
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(MatchaTokens.Colors.glassBorder, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.glassHighlight, lineWidth: 0.5)
        }
    }

    private func loadLatestDeal() async {
        do {
            let read = try await repository.fetchDeal(dealId: deal.id.uuidString)
            applyUpdatedDeal(read)
        } catch {
            // Silently ignore -- deal is already displayed from cache.
        }
    }

    private func acceptDeal() async {
        await performAction {
            let read = try await repository.acceptDeal(dealId: deal.id.uuidString)
            applyUpdatedDeal(read)
        }
    }

    private func declineDeal() async {
        await performAction {
            let read = try await repository.declineDeal(dealId: deal.id.uuidString)
            applyUpdatedDeal(read)
        }
    }

    private func cancelDeal() async {
        await performAction {
            let read = try await repository.cancelDeal(dealId: deal.id.uuidString, reason: "other")
            applyUpdatedDeal(read)
        }
    }

    private func checkInDeal() async {
        await performAction {
            let read = try await repository.checkInDeal(dealId: deal.id.uuidString)
            applyUpdatedDeal(read)
        }
    }

    private func submitReview(_ review: DealReview) async {
        await performAction {
            let read = try await repository.submitReview(
                dealId: deal.id.uuidString,
                review: DealReviewRequest(
                    punctuality: review.punctuality,
                    offerMatch: review.offerMatch,
                    communication: review.communication,
                    comment: review.comment
                )
            )
            applyUpdatedDeal(read)
            showReviewSheet = false
        }
    }

    private func performDestructiveAction() async {
        guard let destructiveAction else { return }
        switch destructiveAction {
        case .decline:
            await declineDeal()
        case .cancel:
            await cancelDeal()
        }
        self.destructiveAction = nil
    }

    private func performAction(_ action: () async throws -> Void) async {
        isPerformingAction = true
        error = nil
        do {
            try await action()
        } catch let networkError as NetworkError {
            self.error = networkError
        } catch {
            self.error = .networkError(error)
        }
        isPerformingAction = false
    }

    private func applyUpdatedDeal(_ read: DealRead) {
        let updatedDeal = mergedDeal(from: read, fallback: deal)
        deal = updatedDeal
        onDealUpdated?(updatedDeal)
    }

    private func mergedDeal(from read: DealRead, fallback: Deal) -> Deal {
        let currentUserID = NetworkService.shared.currentUserID
        let partnerID = read.participantIds.first(where: { $0 != currentUserID })
        let currentUserCheckedIn = currentUserID.map(read.checkedInUserIds.contains) ?? fallback.myCheckInDone
        let partnerCheckedIn = partnerID.map(read.checkedInUserIds.contains) ?? fallback.partnerCheckInDone

        let checkIn: DealCheckIn
        if fallback.myRole == .blogger {
            checkIn = DealCheckIn(
                bloggerConfirmed: currentUserCheckedIn,
                businessConfirmed: partnerCheckedIn,
                windowOpensAt: fallback.checkIn.windowOpensAt
            )
        } else {
            checkIn = DealCheckIn(
                bloggerConfirmed: partnerCheckedIn,
                businessConfirmed: currentUserCheckedIn,
                windowOpensAt: fallback.checkIn.windowOpensAt
            )
        }

        return Deal(
            id: UUID(uuidString: read.id) ?? fallback.id,
            partnerName: fallback.partnerName,
            title: read.offeredText.isEmpty ? fallback.title : ValidationService.sanitize(read.offeredText),
            scheduledDateText: scheduleLabel(for: read.scheduledFor, fallback: fallback.scheduledDateText),
            scheduledDate: read.scheduledFor,
            locationName: read.placeName ?? fallback.locationName,
            status: read.status,
            progressNote: read.requestedText.isEmpty ? fallback.progressNote : ValidationService.sanitize(read.requestedText),
            canRepeat: read.status == .reviewed,
            contentProofStatus: fallback.contentProofStatus,
            dealType: read.type == .paid ? .paid : .barter,
            youOffer: read.offeredText.isEmpty ? fallback.youOffer : ValidationService.sanitize(read.offeredText),
            youReceive: read.requestedText.isEmpty ? fallback.youReceive : ValidationService.sanitize(read.requestedText),
            guests: read.guests == DealGuests.plusOne.rawValue || read.guests == "duo" ? .plusOne : .solo,
            contentDeadline: read.contentDeadline,
            checkIn: checkIn,
            myRole: fallback.myRole,
            bloggerReview: fallback.bloggerReview,
            businessReview: fallback.businessReview,
            contentProof: fallback.contentProof,
            isMine: read.initiatorId == currentUserID
        )
    }

    private func scheduleLabel(for date: Date?, fallback: String) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private enum DestructiveDealAction {
    case decline
    case cancel

    var title: String {
        switch self {
        case .decline:
            return "Decline Deal"
        case .cancel:
            return "Cancel Deal"
        }
    }

    var confirmLabel: String {
        switch self {
        case .decline:
            return "Decline"
        case .cancel:
            return "Yes, Cancel"
        }
    }

    func message(partnerName: String) -> String {
        switch self {
        case .decline:
            return "Decline this collaboration request from \(partnerName)?"
        case .cancel:
            return "Are you sure you want to cancel this deal with \(partnerName)?"
        }
    }
}
