import SwiftUI

// MARK: - Response State

enum OfferResponseState {
    case idle
    case composing
    case sent
    case limitReached
}

// MARK: - OfferDetailView

struct OfferDetailView: View {
    let offer: Offer
    var isBusiness: Bool = false
    var userFollowersCount: Int? = nil

    @State private var responseState: OfferResponseState = .idle
    @State private var responsesUsedToday: Int = 1
    @State private var dailyResponseLimit: Int = 3
    @State private var optionalMessage: String = ""
    @State private var showResponseSheet = false
    @Environment(\.dismiss) private var dismiss

    private var typeColor: Color {
        switch offer.type {
        case .paid:   return MatchaTokens.Colors.success
        case .barter: return MatchaTokens.Colors.warning
        case .both:   return MatchaTokens.Colors.accent
        }
    }

    private var urgencyColor: Color {
        offer.slotsRemaining <= 2 ? MatchaTokens.Colors.danger : MatchaTokens.Colors.textSecondary
    }

    private var responsesLeft: Int {
        max(0, dailyResponseLimit - responsesUsedToday)
    }

    private var isAtDailyLimit: Bool {
        responsesUsedToday >= dailyResponseLimit
    }

    private var minimumFollowersRequired: Int? {
        switch offer.audienceTier {
        case .nano:  return 1_000
        case .micro: return 10_000
        case .mid:   return 100_000
        case .any:   return nil
        }
    }

    private var isBelowMinimumAudience: Bool {
        guard let minimum = minimumFollowersRequired,
              let followers = userFollowersCount else { return false }
        return followers < minimum
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                coverSection
                contentSection
            }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .bottom) {
            if !isBusiness {
                bottomCTA
            }
        }
        .sheet(isPresented: $showResponseSheet) {
            ResponseSheet(
                offer: offer,
                message: $optionalMessage,
                onSend: {
                    withAnimation(MatchaTokens.Animations.cardAppear) {
                        responsesUsedToday += 1
                        responseState = .sent
                    }
                    showResponseSheet = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(MatchaTokens.Colors.background)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .onAppear {
            if isAtDailyLimit { responseState = .limitReached }
        }
    }

    // MARK: - Cover

    private var coverSection: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let url = offer.coverURL {
                    GeometryReader { geo in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: 400)
                                    .clipped()
                            default:
                                coverGradientPlaceholder
                                    .frame(width: geo.size.width, height: 400)
                            }
                        }
                    }
                    .frame(height: 400)
                } else {
                    coverGradientPlaceholder
                        .frame(height: 400)
                }
            }

            // Gradient overlay — smooth fade into background
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: MatchaTokens.Colors.background.opacity(0.4), location: 0.4),
                    .init(color: MatchaTokens.Colors.background.opacity(0.85), location: 0.65),
                    .init(color: MatchaTokens.Colors.background, location: 0.85),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)

            // Type badge — top-right overlay on photo
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: typeIcon)
                            .font(.system(size: 13, weight: .bold))
                        Text(offer.type.title.uppercased())
                            .font(.system(size: 13, weight: .black))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(typeColor.opacity(0.85), in: Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
                }
                Spacer()
            }
            .padding(.top, 58)
            .padding(.trailing, MatchaTokens.Spacing.medium)

            // Title + badges
            VStack(alignment: .leading, spacing: 10) {
                Spacer()

                // Badges row on photo (Last Minute + slots)
                HStack(spacing: 8) {
                    if offer.isLastMinute {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.caption.weight(.bold))
                            Text("Last Minute")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(MatchaTokens.Colors.danger, in: Capsule())
                    }

                    HStack(spacing: 4) {
                        if offer.isUnlimitedSlots {
                            Image(systemName: "infinity")
                                .font(.system(size: 12, weight: .bold))
                            Text("No Limit")
                                .font(.caption.weight(.bold))
                        } else {
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(offer.slotsRemaining) of \(offer.slotsTotal) slots")
                                .font(.caption.weight(.bold))
                        }
                    }
                    .foregroundStyle(offer.isUnlimitedSlots ? MatchaTokens.Colors.accent : urgencyColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        (offer.isUnlimitedSlots ? MatchaTokens.Colors.accent : urgencyColor).opacity(0.15),
                        in: Capsule()
                    )
                }

                Text(offer.title.replacingOccurrences(of: "[LAST MINUTE] ", with: ""))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(3)

                // Reward summary below title
                if !offer.rewardSummary.isEmpty {
                    Text(offer.rewardSummary)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }

                if let location = offer.location {
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption.weight(.bold))
                        Text(location)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.bottom, MatchaTokens.Spacing.large)
        }
        .frame(height: 400)
    }

    private var coverGradientPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [MatchaTokens.Colors.heroGradientTop, MatchaTokens.Colors.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "tag.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.2))
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            exchangeSection
            deliverablesSection
            requirementsSection
            statsSection
        }
        .padding(.horizontal, MatchaTokens.Spacing.large)
        .padding(.top, MatchaTokens.Spacing.small)
        .padding(.bottom, isBusiness ? 40 : 130)
    }

    // MARK: - Creator Row

    private var creatorRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: 48, height: 48)

                if let url = offer.creator.photoURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        } else {
                            initialsCircle(name: offer.creator.name, size: 48)
                        }
                    }
                } else {
                    initialsCircle(name: offer.creator.name, size: 48)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(offer.creator.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    if offer.creator.hasBlueCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x1DA1F2))
                    }
                }

                Text(offer.creator.secondaryLine)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }

            Spacer()

            Text("Business")
                .font(.caption2.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06), in: Capsule())
        }
        .padding(MatchaTokens.Spacing.medium)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Type Badge Row

    private var typeBadgeRow: some View {
        HStack(spacing: 10) {
            Label {
                Text(offer.type.title)
                    .font(.subheadline.weight(.bold))
            } icon: {
                Image(systemName: typeIcon)
                    .font(.subheadline)
            }
            .foregroundStyle(typeColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(typeColor.opacity(0.12), in: Capsule())

            if offer.guests == .plusOne {
                Label("+1 Guest Welcome", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x7EB2FF))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(hex: 0x7EB2FF).opacity(0.1), in: Capsule())
            }

            Spacer()
        }
    }

    private var typeIcon: String {
        switch offer.type {
        case .paid:   return "dollarsign.circle.fill"
        case .barter: return "arrow.trianglehead.2.counterclockwise.rotate.90"
        case .both:   return "plus.circle.fill"
        }
    }

    // MARK: - Exchange Section (Blogger/Business Receives)

    private var exchangeSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Text("The Deal")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            VStack(spacing: 0) {
                // You receive (blogger side)
                exchangeRow(
                    icon: "gift.fill",
                    color: MatchaTokens.Colors.accent,
                    title: "YOU RECEIVE",
                    value: offer.bloggerReceives.isEmpty ? offer.rewardSummary : offer.bloggerReceives,
                    bgColor: MatchaTokens.Colors.accent.opacity(0.06)
                )

                // Visual swap divider
                HStack {
                    Rectangle()
                        .fill(MatchaTokens.Colors.outline)
                        .frame(height: 0.5)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                        .padding(6)
                        .background(MatchaTokens.Colors.elevated, in: Circle())
                    Rectangle()
                        .fill(MatchaTokens.Colors.outline)
                        .frame(height: 0.5)
                }
                .padding(.horizontal, MatchaTokens.Spacing.medium)

                // Business expects
                exchangeRow(
                    icon: "building.2.fill",
                    color: Color(hex: 0x7EB2FF),
                    title: "BUSINESS EXPECTS",
                    value: offer.businessReceives.isEmpty ? offer.deliverableSummary : offer.businessReceives,
                    bgColor: Color(hex: 0x7EB2FF).opacity(0.05)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 0.5)
            }
        }
    }

    private func exchangeRow(icon: String, color: Color, title: String, value: String, bgColor: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.textMuted)
                    .tracking(1)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineSpacing(4)
            }
        }
        .padding(MatchaTokens.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
    }

    // MARK: - Deliverables

    private var deliverablesSection: some View {
        sectionCard(title: "Deliverables") {
            Text(offer.deliverableSummary)
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Requirements

    private var requirementsSection: some View {
        sectionCard(title: "Requirements") {
            VStack(alignment: .leading, spacing: 12) {
                // Preferred niches
                if !offer.preferredNiches.isEmpty {
                    requirementRow(
                        icon: "tag.fill",
                        label: "Preferred Niche",
                        value: offer.preferredNiches.joined(separator: ", "),
                        color: MatchaTokens.Colors.accent
                    )
                } else if let niche = offer.preferredNiche {
                    requirementRow(
                        icon: "tag.fill",
                        label: "Preferred Niche",
                        value: niche,
                        color: MatchaTokens.Colors.accent
                    )
                }

                // Audience tier
                if offer.audienceTier != .any {
                    requirementRow(
                        icon: "person.2.fill",
                        label: "Minimum Audience",
                        value: offer.audienceTier.label,
                        color: Color(hex: 0x7EB2FF)
                    )
                } else if let audience = offer.minimumAudience {
                    requirementRow(
                        icon: "person.2.fill",
                        label: "Minimum Audience",
                        value: audience,
                        color: Color(hex: 0x7EB2FF)
                    )
                }

                // Special conditions
                if let conditions = offer.specialConditions, !conditions.isEmpty {
                    requirementRow(
                        icon: "star.fill",
                        label: "Special Conditions",
                        value: conditions,
                        color: MatchaTokens.Colors.warning
                    )
                }

                if offer.preferredNiches.isEmpty
                    && offer.preferredNiche == nil
                    && offer.audienceTier == .any
                    && offer.minimumAudience == nil
                    && (offer.specialConditions == nil || offer.specialConditions!.isEmpty) {
                    Text("No specific requirements")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
        }
    }

    private func requirementRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            Text("Stats")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: MatchaTokens.Spacing.small),
                GridItem(.flexible(), spacing: MatchaTokens.Spacing.small)
            ], spacing: MatchaTokens.Spacing.small) {
                statCell(
                    icon: offer.isUnlimitedSlots ? "infinity" : "ticket.fill",
                    value: offer.isUnlimitedSlots ? "Open" : "\(offer.slotsRemaining)/\(offer.slotsTotal)",
                    label: offer.isUnlimitedSlots ? "No Limit" : "Slots Open",
                    color: offer.isUnlimitedSlots ? MatchaTokens.Colors.accent : urgencyColor
                )

                statCell(
                    icon: "person.crop.circle.badge.checkmark",
                    value: "\(offer.respondedCount)",
                    label: "Applied",
                    color: MatchaTokens.Colors.baliBlue
                )

                statCell(
                    icon: "clock.fill",
                    value: offer.expiryText,
                    label: "Deadline",
                    color: MatchaTokens.Colors.warning
                )

                if let posted = offer.postedDate {
                    statCell(
                        icon: "calendar",
                        value: posted,
                        label: "Posted",
                        color: MatchaTokens.Colors.textSecondary
                    )
                } else {
                    statCell(
                        icon: "star.fill",
                        value: offer.type.title,
                        label: "Type",
                        color: typeColor
                    )
                }
            }
        }
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .padding(MatchaTokens.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Response counter
                responseCounterRow

                // Main action button
                actionButton
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.top, 12)
            .padding(.bottom, MatchaTokens.Spacing.large)
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private var responseCounterRow: some View {
        switch responseState {
        case .sent:
            EmptyView()
        case .limitReached:
            HStack(spacing: 6) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.warning)
                Text("Come back tomorrow")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
        default:
            HStack(spacing: 6) {
                Image(systemName: "arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                Text("\(responsesLeft) of \(dailyResponseLimit) responses left today")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch responseState {
        case .sent:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.success)
                Text("Response sent")
                    .font(.headline)
                    .foregroundStyle(MatchaTokens.Colors.success)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(MatchaTokens.Colors.success.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .transition(.opacity.combined(with: .scale(scale: 0.95)))

        case .limitReached:
            Button(action: {}) {
                HStack(spacing: 10) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.body.weight(.semibold))
                    Text("Come back tomorrow ☕")
                        .font(.headline)
                }
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(true)

        default:
            if isBelowMinimumAudience, let minimum = minimumFollowersRequired {
                VStack(spacing: 6) {
                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.body.weight(.semibold))
                            Text("I'm Interested")
                                .font(.headline)
                        }
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(true)

                    Text("Requires at least \(minimum.formatted()) followers")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            } else {
                Button(action: { showResponseSheet = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.body.weight(.semibold))
                        Text("I'm Interested")
                            .font(.headline)
                    }
                    .foregroundStyle(MatchaTokens.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: MatchaTokens.Colors.accent.opacity(0.3), radius: 12, y: 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            content()
        }
        .padding(MatchaTokens.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func initialsCircle(name: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(MatchaTokens.Colors.elevated)
                .frame(width: size, height: size)
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }
}

// MARK: - ResponseSheet

private struct ResponseSheet: View {
    let offer: Offer
    @Binding var message: String
    let onSend: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(MatchaTokens.Colors.outline)
                .frame(width: 36, height: 4)
                .padding(.top, MatchaTokens.Spacing.medium)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.large) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Respond to Offer")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        Text(offer.title)
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    .padding(.top, MatchaTokens.Spacing.medium)

                    // Business info
                    HStack(spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                        Text(offer.creator.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        if offer.creator.hasBlueCheck {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(Color(hex: 0x1DA1F2))
                        }
                    }

                    Divider().background(MatchaTokens.Colors.outline)

                    // Message field
                    VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                        Text("Optional Message")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                            .tracking(1)

                        TextField(
                            "Introduce yourself or ask a question...",
                            text: $message,
                            axis: .vertical
                        )
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(5, reservesSpace: false)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    message.isEmpty ? MatchaTokens.Colors.outline : MatchaTokens.Colors.accent.opacity(0.3),
                                    lineWidth: 1
                                )
                        )

                        Text("Your profile and stats will be shared automatically")
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.bottom, MatchaTokens.Spacing.large)
            }

            // Send button
            VStack(spacing: 0) {
                Divider().background(MatchaTokens.Colors.outline)

                HStack(spacing: MatchaTokens.Spacing.small) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .frame(width: 80)
                        .padding(.vertical, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button(action: onSend) {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.body.weight(.medium))
                            Text("Send Response")
                                .font(.headline)
                        }
                        .foregroundStyle(MatchaTokens.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.vertical, MatchaTokens.Spacing.medium)
                .background(MatchaTokens.Colors.background)
            }
        }
    }
}
