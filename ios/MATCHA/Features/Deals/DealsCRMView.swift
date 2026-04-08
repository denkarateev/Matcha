import SwiftUI

// MARK: - DealsCRMView
/// Admin CRM panel for viewing, filtering, and inspecting all deals.

struct DealsCRMView: View {
    @StateObject private var vm = DealsCRMViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: MatchaTokens.Spacing.medium) {
                header
                statusSummaryBar
                filterBar
                dealsList
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.bottom, MatchaTokens.Spacing.xLarge)
        }
        .background(MatchaTokens.backgroundGradient.ignoresSafeArea())
        .task { await vm.loadDeals() }
        .refreshable { await vm.loadDeals() }
    }

    // MARK: - Header

    private var header: some View {
        MatchaSectionHeader(
            eyebrow: "ADMIN",
            title: "Deals CRM",
            subtitle: "All deals across the platform",
            badgeText: "\(vm.allDeals.count) total"
        )
        .padding(.top, MatchaTokens.Spacing.medium)
    }

    // MARK: - Status Summary Bar

    private var statusSummaryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MatchaTokens.Spacing.small) {
                ForEach(DealsCRMViewModel.StatusFilter.allCases) { filter in
                    if filter != .all {
                        statusChip(filter: filter)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, MatchaTokens.Spacing.xSmall)
    }

    private func statusChip(filter: DealsCRMViewModel.StatusFilter) -> some View {
        let count = vm.count(for: filter)
        let color = filter.color

        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(filter.title)
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            Text("\(count)")
                .font(MatchaTokens.Typography.caption.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: MatchaTokens.Radius.pill)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MatchaTokens.Spacing.small) {
                ForEach(DealsCRMViewModel.StatusFilter.allCases) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func filterPill(_ filter: DealsCRMViewModel.StatusFilter) -> some View {
        let isSelected = vm.selectedFilter == filter
        let color = filter == .all ? MatchaTokens.Colors.accent : filter.color

        return Button {
            withAnimation(MatchaTokens.Animations.tabSwitch) {
                vm.selectedFilter = filter
            }
        } label: {
            Text(filter.title)
                .font(MatchaTokens.Typography.caption.weight(.semibold))
                .foregroundStyle(isSelected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule(style: .continuous)
                            .fill(color)
                    } else {
                        Capsule(style: .continuous)
                            .fill(MatchaTokens.Colors.glassFill)
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 0.75)
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Deals List

    private var dealsList: some View {
        Group {
            if vm.filteredDeals.isEmpty {
                emptyState
            } else {
                ForEach(vm.filteredDeals) { deal in
                    DealsCRMRow(deal: deal, isExpanded: vm.expandedDealId == deal.id) {
                        withAnimation(MatchaTokens.Animations.cardAppear) {
                            vm.toggleExpanded(deal.id)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.textMuted)

            Text("No deals found")
                .font(MatchaTokens.Typography.headline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            Text("Try changing the filter")
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - DealsCRMRow

private struct DealsCRMRow: View {
    let deal: DealRead
    let isExpanded: Bool
    let onTap: () -> Void

    private var statusColor: Color {
        switch deal.status {
        case .draft:     MatchaTokens.Colors.textMuted
        case .confirmed: MatchaTokens.Colors.baliBlue
        case .visited:   MatchaTokens.Colors.success
        case .reviewed:  MatchaTokens.Colors.accent
        case .cancelled: MatchaTokens.Colors.danger
        case .noShow:    MatchaTokens.Colors.warning
        }
    }

    private var typeLabel: String {
        deal.type.title
    }

    private var typeColor: Color {
        switch deal.type {
        case .barter: MatchaTokens.Colors.sand
        case .paid:   MatchaTokens.Colors.accent
        case .both:   MatchaTokens.Colors.baliBlue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Compact row (always visible)
            compactRow
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

            // Expanded details
            if isExpanded {
                expandedDetails
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(MatchaTokens.Spacing.medium)
        .liquidGlass()
        .matchaShadow(.level1)
    }

    // MARK: Compact Row

    private var compactRow: some View {
        HStack(spacing: 12) {
            // Status indicator dot
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .shadow(color: statusColor.opacity(0.5), radius: 4)

            // Partner + meta
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(partnerLabel)
                        .font(MatchaTokens.Typography.headline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .lineLimit(1)

                    typeBadge
                }

                HStack(spacing: 10) {
                    if let date = deal.scheduledFor {
                        metaLabel(icon: "calendar", text: formattedDate(date))
                    }

                    if let place = deal.placeName, !place.isEmpty {
                        metaLabel(icon: "mappin", text: place)
                    }
                }
            }

            Spacer(minLength: 0)

            // Status badge
            statusBadge

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textMuted)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
    }

    private var partnerLabel: String {
        // Show participant IDs; in a real scenario you'd resolve these to names
        let ids = deal.participantIds
        if ids.count >= 2 {
            let short0 = String(ids[0].prefix(6))
            let short1 = String(ids[1].prefix(6))
            return "\(short0) <> \(short1)"
        }
        return ids.first.map { String($0.prefix(8)) } ?? "Unknown"
    }

    private var statusBadge: some View {
        Text(deal.status.title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(statusColor)
            .tracking(0.6)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.12), in: Capsule())
            .overlay(Capsule().strokeBorder(statusColor.opacity(0.25), lineWidth: 0.75))
    }

    private var typeBadge: some View {
        Text(typeLabel)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(typeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(typeColor.opacity(0.12), in: Capsule())
    }

    private func metaLabel(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(MatchaTokens.Typography.caption)
                .lineLimit(1)
        }
        .foregroundStyle(MatchaTokens.Colors.textSecondary)
    }

    // MARK: Expanded Details

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Divider()
                .background(MatchaTokens.Colors.outline)
                .padding(.vertical, MatchaTokens.Spacing.xSmall)

            // IDs
            detailRow(label: "Deal ID", value: deal.id)
            detailRow(label: "Chat ID", value: deal.chatId)
            detailRow(label: "Initiator", value: String(deal.initiatorId.prefix(12)) + "...")

            // Participants
            detailRow(label: "Participants", value: deal.participantIds.joined(separator: "\n"))

            // Offer details
            if !deal.offeredText.isEmpty {
                detailRow(label: "Offered", value: deal.offeredText)
            }
            if !deal.requestedText.isEmpty {
                detailRow(label: "Requested", value: deal.requestedText)
            }

            // Location + guests
            if let place = deal.placeName, !place.isEmpty {
                detailRow(label: "Location", value: place)
            }
            detailRow(label: "Guests", value: deal.guests)

            // Dates
            if let scheduled = deal.scheduledFor {
                detailRow(label: "Scheduled", value: formattedDateFull(scheduled))
            }
            if let deadline = deal.contentDeadline {
                detailRow(label: "Content Deadline", value: formattedDateFull(deadline))
            }
            detailRow(label: "Created", value: formattedDateFull(deal.createdAt))
            detailRow(label: "Updated", value: formattedDateFull(deal.updatedAt))

            // Check-ins
            if !deal.checkedInUserIds.isEmpty {
                detailRow(label: "Checked In", value: deal.checkedInUserIds.map { String($0.prefix(8)) }.joined(separator: ", "))
            }

            // Cancellation
            if let reason = deal.cancellationReason, !reason.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Text("Cancel Reason")
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                        .frame(width: 100, alignment: .leading)

                    Text(reason)
                        .font(MatchaTokens.Typography.caption.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.danger)
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textMuted)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(MatchaTokens.Typography.caption.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .textSelection(.enabled)
        }
    }

    // MARK: Date Formatting

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    private func formattedDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - DealsCRMViewModel

@MainActor
final class DealsCRMViewModel: ObservableObject {

    // MARK: Status Filter

    enum StatusFilter: String, CaseIterable, Identifiable {
        case all
        case draft
        case confirmed
        case visited
        case reviewed
        case cancelled
        case noShow

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:       "All"
            case .draft:     "Draft"
            case .confirmed: "Confirmed"
            case .visited:   "Visited"
            case .reviewed:  "Reviewed"
            case .cancelled: "Cancelled"
            case .noShow:    "No-Show"
            }
        }

        var color: Color {
            switch self {
            case .all:       MatchaTokens.Colors.accent
            case .draft:     MatchaTokens.Colors.textMuted
            case .confirmed: MatchaTokens.Colors.baliBlue
            case .visited:   MatchaTokens.Colors.success
            case .reviewed:  MatchaTokens.Colors.accent
            case .cancelled: MatchaTokens.Colors.danger
            case .noShow:    MatchaTokens.Colors.warning
            }
        }

        var dealStatus: DealStatus? {
            switch self {
            case .all:       nil
            case .draft:     .draft
            case .confirmed: .confirmed
            case .visited:   .visited
            case .reviewed:  .reviewed
            case .cancelled: .cancelled
            case .noShow:    .noShow
            }
        }
    }

    // MARK: State

    @Published var allDeals: [DealRead] = []
    @Published var selectedFilter: StatusFilter = .all
    @Published var expandedDealId: String?
    @Published var isLoading = false

    // MARK: Computed

    var filteredDeals: [DealRead] {
        let filtered: [DealRead]
        if let status = selectedFilter.dealStatus {
            filtered = allDeals.filter { $0.status == status }
        } else {
            filtered = allDeals
        }
        // Sort by date, newest first
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    func count(for filter: StatusFilter) -> Int {
        guard let status = filter.dealStatus else { return allDeals.count }
        return allDeals.filter { $0.status == status }.count
    }

    // MARK: Actions

    func toggleExpanded(_ dealId: String) {
        if expandedDealId == dealId {
            expandedDealId = nil
        } else {
            expandedDealId = dealId
        }
    }

    func loadDeals() async {
        // Integrates with MatchaRepository.fetchDeals()
        // In production, inject the repository; here we mark loading state.
        isLoading = true
        defer { isLoading = false }

        // Placeholder: replace with actual repository call
        // e.g.:
        // do {
        //     allDeals = try await repository.fetchDeals()
        // } catch {
        //     // handle error
        // }
    }
}

// MARK: - Preview

#Preview("Deals CRM") {
    let sampleDeals: [DealRead] = [
        DealRead(
            id: "deal-001",
            chatId: "chat-100",
            participantIds: ["user-alice", "user-bob"],
            initiatorId: "user-alice",
            type: .barter,
            offeredText: "2 Reels + 5 Stories",
            requestedText: "Dinner for 2 at sunset table",
            placeName: "The Lawn Canggu",
            guests: "plus_one",
            scheduledFor: Date().addingTimeInterval(86400),
            contentDeadline: Date().addingTimeInterval(86400 * 3),
            status: .confirmed,
            checkedInUserIds: [],
            cancellationReason: nil,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            updatedAt: Date()
        ),
        DealRead(
            id: "deal-002",
            chatId: "chat-101",
            participantIds: ["user-carol", "user-dave"],
            initiatorId: "user-carol",
            type: .paid,
            offeredText: "1 Hero Reel + 5 Photos",
            requestedText: "$500 + 2-night stay",
            placeName: "COMO Uma Canggu",
            guests: "solo",
            scheduledFor: Date().addingTimeInterval(86400 * 3),
            contentDeadline: Date().addingTimeInterval(86400 * 7),
            status: .draft,
            checkedInUserIds: [],
            cancellationReason: nil,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date()
        ),
        DealRead(
            id: "deal-003",
            chatId: "chat-102",
            participantIds: ["user-eve", "user-frank"],
            initiatorId: "user-eve",
            type: .barter,
            offeredText: "3 Stories mentioning venue",
            requestedText: "Free spa session",
            placeName: "Spring Spa",
            guests: "solo",
            scheduledFor: Date().addingTimeInterval(-86400),
            contentDeadline: nil,
            status: .visited,
            checkedInUserIds: ["user-eve", "user-frank"],
            cancellationReason: nil,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        DealRead(
            id: "deal-004",
            chatId: "chat-103",
            participantIds: ["user-grace", "user-henry"],
            initiatorId: "user-henry",
            type: .paid,
            offeredText: "Full brand photoshoot",
            requestedText: "$1200",
            placeName: nil,
            guests: "solo",
            scheduledFor: nil,
            contentDeadline: nil,
            status: .reviewed,
            checkedInUserIds: ["user-grace", "user-henry"],
            cancellationReason: nil,
            createdAt: Date().addingTimeInterval(-86400 * 10),
            updatedAt: Date().addingTimeInterval(-86400 * 3)
        ),
        DealRead(
            id: "deal-005",
            chatId: "chat-104",
            participantIds: ["user-ivan", "user-julia"],
            initiatorId: "user-ivan",
            type: .barter,
            offeredText: "TikTok video",
            requestedText: "Brunch for 2",
            placeName: "Revolver Espresso",
            guests: "plus_one",
            scheduledFor: Date().addingTimeInterval(-86400 * 2),
            contentDeadline: nil,
            status: .cancelled,
            checkedInUserIds: [],
            cancellationReason: "Schedule conflict",
            createdAt: Date().addingTimeInterval(-86400 * 7),
            updatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        DealRead(
            id: "deal-006",
            chatId: "chat-105",
            participantIds: ["user-kate", "user-leo"],
            initiatorId: "user-kate",
            type: .both,
            offeredText: "Reel + Stories + Photo set",
            requestedText: "Room upgrade + $150",
            placeName: "W Bali Seminyak",
            guests: "solo",
            scheduledFor: Date().addingTimeInterval(-86400 * 1),
            contentDeadline: nil,
            status: .noShow,
            checkedInUserIds: ["user-kate"],
            cancellationReason: nil,
            createdAt: Date().addingTimeInterval(-86400 * 4),
            updatedAt: Date().addingTimeInterval(-86400)
        ),
    ]

    let vm = DealsCRMViewModel()
    vm.allDeals = sampleDeals

    return DealsCRMView(viewModel: vm)
        .preferredColorScheme(.dark)
}

extension DealsCRMView {
    /// Initializer accepting an external view model (previews / testing).
    init(viewModel: DealsCRMViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }
}
