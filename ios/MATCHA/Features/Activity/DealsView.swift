import Observation
import SwiftUI

struct DealsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var store: DealsStore
    @State private var selectedApplicant: UserProfile?

    init(currentUser: UserProfile, repository: any MatchaRepository) {
        self.currentUser = currentUser
        self.repository = repository
        _store = State(initialValue: DealsStore(repository: repository))
    }

    private var visibleDeals: [Deal] {
        let feed = store.activeDeals
            + store.finishedDeals.filter { $0.status == .visited }
            + store.noShowDeals

        return feed.sorted { lhs, rhs in
            let leftRank = dealRank(lhs)
            let rightRank = dealRank(rhs)
            if leftRank != rightRank {
                return leftRank < rightRank
            }

            return (lhs.scheduledDate ?? .distantFuture) < (rhs.scheduledDate ?? .distantFuture)
        }
    }

    private var archivedCount: Int {
        store.finishedDeals.filter { $0.status == .reviewed }.count + store.cancelledDeals.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.large) {
                if let error = store.error {
                    errorBanner(error)
                }

                introCard

                if !store.responses.isEmpty {
                    requestsSection
                }

                if visibleDeals.isEmpty {
                    if store.responses.isEmpty {
                        emptyState
                    }
                } else {
                    dealsSection
                }

                if archivedCount > 0 {
                    archivedHint
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.bottom, 100)
        }
        .refreshable { await store.load() }
        .onAppear {
            guard store.hasLoaded else { return }
            Task { await store.load() }
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        // Title handled by parent OffersAndDealsView
        .navigationDestination(for: Deal.self) { deal in
            DealDetailView(repository: repository, onDealUpdated: { _ in
                Task { await store.load() }
            }, deal: deal)
        }
        .sheet(item: $selectedApplicant) { profile in
            NavigationStack {
                ProfileDetailView(profile: profile)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task { await store.loadIfNeeded() }
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            sectionHeader(
                title: currentUser.role == .business ? "Requests" : "Applications",
                subtitle: currentUser.role == .business
                    ? "Incoming offer replies stay in the same inbox as your deal cards."
                    : "The offers you answered stay here together with your live deals."
            )

            LazyVStack(spacing: MatchaTokens.Spacing.medium) {
                ForEach(store.responses) { application in
                    requestCard(application)
                }
            }
        }
    }

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            sectionHeader(
                title: "Live deals",
                subtitle: "Open proposals, confirmed visits, and review-ready collabs."
            )

            LazyVStack(spacing: MatchaTokens.Spacing.medium) {
                ForEach(visibleDeals) { deal in
                    NavigationLink(value: deal) {
                        dealCard(deal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func requestCard(_ application: OfferApplication) -> some View {
        Button {
            selectedApplicant = application.applicant
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    MatchaAvatar(
                        url: application.applicant.photoURL,
                        initials: application.applicant.name,
                        size: .medium,
                        hasBlueCheck: application.applicant.hasBlueCheck
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(application.applicant.name)
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                                .lineLimit(1)

                            if application.applicant.hasBlueCheck {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(MatchaTokens.Colors.baliBlue)
                            }
                        }

                        Text(application.applicant.secondaryLine)
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    statusPill(
                        application.statusText,
                        highlighted: application.isActionRequired
                    )
                }

                Text(application.offerTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    metaChip(icon: "clock", text: application.submittedAt)
                    if let district = application.applicant.district ?? application.applicant.locationDistrict {
                        metaChip(icon: "mappin.and.ellipse", text: district)
                    }
                }

                HStack(spacing: 8) {
                    if application.isActionRequired {
                        statusPill("Open now", highlighted: true)
                    }

                    Text(requestNote(for: application))
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Text("Profile")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func requestNote(for application: OfferApplication) -> String {
        if application.isActionRequired {
            return "Open the profile and decide whether to move this toward a deal."
        }

        return currentUser.role == .business
            ? "This response is already handled and stays here for context."
            : "Your offer application stays visible here while the business decides."
    }

    private func statusPill(_ text: String, highlighted: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(highlighted ? .black : MatchaTokens.Colors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                highlighted ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                in: Capsule()
            )
    }

    private func locationLabel(for deal: Deal) -> String {
        guard let locationName = deal.locationName?.trimmingCharacters(in: .whitespacesAndNewlines), !locationName.isEmpty else {
            return "Location TBD"
        }
        return locationName
    }

    private func locationIcon(for deal: Deal) -> String {
        if let locationName = deal.locationName?.trimmingCharacters(in: .whitespacesAndNewlines), !locationName.isEmpty {
            return "mappin.and.ellipse"
        }
        return "mappin.slash"
    }

    private func errorBanner(_ error: NetworkError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.body.weight(.medium))
            Text(error.errorDescription ?? "Connection error")
                .font(.subheadline)
                .lineLimit(3)
            Spacer()
            Button("Retry") { Task { await store.load() } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wallet.pass.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                Text("Deals inbox")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }

            Text("Incoming requests, offer responses, and active collabs stay together here so the flow stays simple.")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func dealCard(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(cardHeadline(for: deal))
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    Text(deal.partnerName)
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }

                Spacer(minLength: 0)

                DealStatusBadge(status: deal.status)
            }

            Text(deal.title.isEmpty ? deal.youOffer : deal.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .lineLimit(3)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    metaChip(icon: "calendar.badge.clock", text: deal.scheduledDateText)
                    metaChip(icon: locationIcon(for: deal), text: locationLabel(for: deal))
                }

                if !deal.youReceive.isEmpty {
                    metaChip(icon: "sparkles", text: deal.youReceive)
                }
            }

            DealPipelineView(deal: deal, compact: true)

            HStack(spacing: 8) {
                if let pill = supplementalPill(for: deal) {
                    Text(pill)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(pillForeground(for: deal))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(pillBackground(for: deal), in: Capsule())
                }

                Text(cardNote(for: deal))
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Text("Open")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }
        }
        .padding(MatchaTokens.Spacing.medium)
        .liquidGlass(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(dealStatusColor(deal).opacity(0.25), lineWidth: 1)
        )
    }

    private func dealStatusColor(_ deal: Deal) -> Color {
        switch deal.status {
        case .draft:      return MatchaTokens.Colors.textMuted
        case .confirmed:  return MatchaTokens.Colors.baliBlue
        case .visited:    return MatchaTokens.Colors.success
        case .reviewed:   return MatchaTokens.Colors.accent
        case .cancelled:  return MatchaTokens.Colors.danger
        case .noShow:     return MatchaTokens.Colors.warning
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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.25))
            Text(archivedCount > 0 ? "No open inbox items" : "No deals yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Text(
                archivedCount > 0
                    ? "Archived deals are hidden from the main inbox so current work stays in focus."
                    : "Matches, offer replies, and deal proposals will appear here."
            )
            .font(.subheadline)
            .foregroundStyle(MatchaTokens.Colors.textSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var archivedHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "archivebox.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
            Text("\(archivedCount) archived deal\(archivedCount == 1 ? "" : "s") are hidden from the main inbox.")
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func dealRank(_ deal: Deal) -> Int {
        switch deal.status {
        case .draft where !deal.isMine:
            return 0
        case .draft:
            return 1
        case .confirmed:
            return 2
        case .visited:
            return 3
        case .noShow:
            return 4
        case .reviewed:
            return 5
        case .cancelled:
            return 6
        }
    }

    private func cardHeadline(for deal: Deal) -> String {
        switch deal.status {
        case .draft:
            return deal.isMine ? "Proposal sent" : "Deal request"
        case .confirmed:
            return "Confirmed visit"
        case .visited:
            return "Review pending"
        case .noShow:
            return "No-show follow-up"
        case .reviewed:
            return "Deal completed"
        case .cancelled:
            return "Deal cancelled"
        }
    }

    private func cardNote(for deal: Deal) -> String {
        switch deal.status {
        case .draft:
            return deal.isMine
                ? "Waiting for the other side to respond."
                : "Open the card to review the proposal."
        case .confirmed:
            return deal.myCheckInDone
                ? "Your check-in is done. Waiting for the other side."
                : "Visit is confirmed. Next step is check-in."
        case .visited:
            return deal.myReview == nil
                ? "Visit is complete. Leave a review next."
                : "Your review is in. Waiting for the other side."
        case .noShow:
            return "This visit was marked as a no-show. Review is still available."
        case .reviewed:
            return "Both sides completed the collaboration."
        case .cancelled:
            return "This collaboration request was cancelled."
        }
    }

    private func supplementalPill(for deal: Deal) -> String? {
        switch deal.status {
        case .draft where !deal.isMine:
            return "Needs response"
        case .draft:
            return "Waiting"
        case .visited where deal.myReview == nil:
            return "Review"
        case .confirmed where !deal.myCheckInDone:
            return "Check-In"
        default:
            return nil
        }
    }

    private func pillForeground(for deal: Deal) -> Color {
        switch deal.status {
        case .draft where !deal.isMine:
            return .black
        case .confirmed, .visited:
            return .black
        default:
            return MatchaTokens.Colors.textPrimary
        }
    }

    private func pillBackground(for deal: Deal) -> Color {
        switch deal.status {
        case .draft where !deal.isMine:
            return MatchaTokens.Colors.accent
        case .confirmed:
            return MatchaTokens.Colors.accent.opacity(0.85)
        case .visited:
            return MatchaTokens.Colors.warning
        default:
            return MatchaTokens.Colors.elevated
        }
    }
}

@MainActor
@Observable
final class DealsStore {
    private let repository: any MatchaRepository

    var summary = ActivitySummary(
        likes: [],
        activeDeals: [],
        finishedDeals: [],
        cancelledDeals: [],
        noShowDeals: [],
        applications: []
    )
    var backendDeals: [DealRead] = []
    var matchedLikeIDs: Set<UUID> = []
    var likeBackInFlightIDs: Set<UUID> = []
    var error: NetworkError?
    var hasLoaded = false

    var activeDeals: [Deal] {
        mergedDeals(
            summary.activeDeals,
            including: [.confirmed, .draft]
        )
    }

    var finishedDeals: [Deal] {
        mergedDeals(
            summary.finishedDeals,
            including: [.reviewed, .visited]
        )
    }

    var cancelledDeals: [Deal] {
        mergedDeals(
            summary.cancelledDeals,
            including: [.cancelled]
        )
    }

    var noShowDeals: [Deal] {
        mergedDeals(
            summary.noShowDeals,
            including: [.noShow]
        )
    }

    var responses: [OfferApplication] { summary.applications }
    private var currentUserID: String? {
        NetworkService.shared.currentUserID
    }

    var likes: [UserProfile] {
        ProcessedDiscoveryProfileStore.filter(summary.likes, currentUserID: currentUserID)
    }
    var totalDealCount: Int { activeDeals.count + finishedDeals.count + cancelledDeals.count + noShowDeals.count }

    init(repository: any MatchaRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        error = nil
        hasLoaded = true
        var dealsError: NetworkError?
        var summaryError: NetworkError?

        do {
            backendDeals = try await repository.fetchDeals()
        } catch let networkError as NetworkError {
            dealsError = networkError
            backendDeals = []
        } catch {
            dealsError = .networkError(error)
            backendDeals = []
        }

        do {
            summary = try await repository.fetchActivitySummary()
        } catch let networkError as NetworkError {
            summaryError = networkError
            summary = ActivitySummary(
                likes: [],
                activeDeals: [],
                finishedDeals: [],
                cancelledDeals: [],
                noShowDeals: [],
                applications: []
            )
        } catch {
            summaryError = .networkError(error)
            summary = ActivitySummary(
                likes: [],
                activeDeals: [],
                finishedDeals: [],
                cancelledDeals: [],
                noShowDeals: [],
                applications: []
            )
        }

        let hasAnyActivityData =
            !backendDeals.isEmpty ||
            !likes.isEmpty ||
            !summary.activeDeals.isEmpty ||
            !summary.finishedDeals.isEmpty ||
            !summary.cancelledDeals.isEmpty ||
            !summary.noShowDeals.isEmpty ||
            !summary.applications.isEmpty

        self.error = hasAnyActivityData ? nil : (dealsError ?? summaryError)
    }

    func likeBack(profile: UserProfile) async {
        guard !likeBackInFlightIDs.contains(profile.id), !matchedLikeIDs.contains(profile.id) else {
            return
        }

        likeBackInFlightIDs.insert(profile.id)
        defer { likeBackInFlightIDs.remove(profile.id) }

        do {
            let targetId = profile.serverUserId.isEmpty ? profile.id.uuidString : profile.serverUserId
            _ = try await repository.matchBack(targetId: targetId)
            matchedLikeIDs.insert(profile.id)
            ProcessedDiscoveryProfileStore.add(profile.id, currentUserID: currentUserID)
            summary = ActivitySummary(
                likes: summary.likes.filter { $0.id != profile.id },
                activeDeals: summary.activeDeals,
                finishedDeals: summary.finishedDeals,
                cancelledDeals: summary.cancelledDeals,
                noShowDeals: summary.noShowDeals,
                applications: summary.applications
            )
            error = nil
        } catch let networkError as NetworkError {
            self.error = likes.isEmpty ? networkError : nil
        } catch {
            self.error = likes.isEmpty ? .networkError(error) : nil
        }
    }

    private func mergedDeals(
        _ summaryDeals: [Deal],
        including statuses: Set<DealStatus>
    ) -> [Deal] {
        let legacyDeals = backendDeals
            .filter { statuses.contains($0.status) }
            .map { Self.makeLegacyDeal(from: $0) }

        var legacyByID = Dictionary(legacyDeals.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        var merged = summaryDeals.map { summaryDeal in
            guard let legacyDeal = legacyByID.removeValue(forKey: summaryDeal.id) else {
                return summaryDeal
            }
            return Self.enriched(summaryDeal, fallback: legacyDeal)
        }

        merged.append(contentsOf: legacyByID.values)
        return merged
    }

    static func enriched(_ deal: Deal, fallback: Deal) -> Deal {
        var merged = deal
        if merged.locationName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            merged.locationName = fallback.locationName
        }
        if merged.scheduledDate == nil {
            merged.scheduledDate = fallback.scheduledDate
        }
        return merged
    }

    static func makeLegacyDeal(from deal: DealRead) -> Deal {
        let dateText: String = {
            guard let date = deal.scheduledFor else { return "TBD" }
            let fmt = DateFormatter()
            fmt.dateStyle = .short
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }()

        let currentUserID = NetworkService.shared.currentUserID
        let partner = deal.participantIds.first(where: { $0 != currentUserID }) ?? deal.participantIds.first ?? "Partner"

        return Deal(
            id: UUID(uuidString: deal.id) ?? UUID(),
            partnerName: partner,
            title: deal.offeredText,
            scheduledDateText: dateText,
            scheduledDate: deal.scheduledFor,
            locationName: deal.placeName,
            status: deal.status,
            progressNote: deal.requestedText,
            canRepeat: deal.status == .reviewed,
            contentProofStatus: nil,
            dealType: deal.type == .paid ? .paid : .barter,
            youOffer: deal.offeredText,
            youReceive: deal.requestedText,
            guests: deal.guests == "plus_one" ? .plusOne : .solo,
            contentDeadline: deal.contentDeadline,
            checkIn: DealCheckIn(),
            myRole: NetworkService.shared.currentUserRole ?? .blogger,
            bloggerReview: nil,
            businessReview: nil,
            contentProof: nil,
            isMine: deal.initiatorId == currentUserID
        )
    }
}

#Preview {
    NavigationStack {
        DealsView(
            currentUser: MockSeedData.makeCurrentUser(role: .blogger, name: "Nadia"),
            repository: MockMatchaRepository()
        )
    }
    .preferredColorScheme(.dark)
}
