import Observation
import SwiftUI

struct OffersView: View {
    @State private var store: OffersStore
    @State private var showAllBestForYou = false
    @Binding private var searchText: String
    @Binding private var filterState: OfferFilterState
    @Binding private var allOffers: [Offer]

    var isBusiness: Bool

    init(
        repository: any MatchaRepository,
        isBusiness: Bool = false,
        searchText: Binding<String> = .constant(""),
        filterState: Binding<OfferFilterState> = .constant(OfferFilterState()),
        allOffers: Binding<[Offer]> = .constant([])
    ) {
        _store = State(initialValue: OffersStore(repository: repository))
        _searchText = searchText
        _filterState = filterState
        _allOffers = allOffers
        self.isBusiness = isBusiness
    }

    private func apiFilters(from state: OfferFilterState) -> OfferFilterParams {
        // Backend supports only single niche — keep everything client-side.
        // Frontend's Set<String> lets users pick multiple niches at once.
        OfferFilterParams()
    }

    private var filteredOffers: [Offer] {
        var result = store.offers

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query)
                || $0.creator.name.lowercased().contains(query)
                || ($0.preferredNiche?.lowercased().contains(query) ?? false)
                || $0.rewardSummary.lowercased().contains(query)
            }
        }

        // Collab type filter
        if let type = filterState.collabType {
            result = result.filter { $0.type == type }
        }

        // Niches filter — case-insensitive, checks offer.preferredNiche + preferredNiches
        if !filterState.selectedNiches.isEmpty {
            let selected = Set(filterState.selectedNiches.map { $0.lowercased() })
            result = result.filter { offer in
                var offerNiches = Set(offer.preferredNiches.map { $0.lowercased() })
                if let primary = offer.preferredNiche {
                    offerNiches.insert(primary.lowercased())
                }
                return !selected.isDisjoint(with: offerNiches)
            }
        }

        // Last minute only
        if filterState.lastMinuteOnly {
            result = result.filter(\.isLastMinute)
        }

        return result
    }

    private var lastMinuteOffers: [Offer] {
        filteredOffers.filter(\.isLastMinute)
    }

    private var bestForYouOffers: [Offer] {
        filteredOffers
            .filter { !$0.isLastMinute }
            .prefix(8)
            .map { $0 }
    }

    private var allRegularOffers: [Offer] {
        filteredOffers.filter { !$0.isLastMinute }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Error
                if store.error != nil {
                    errorBanner
                        .padding(.top, 8)
                }

                // Skeleton loading
                if store.isLoading && store.offers.isEmpty {
                    offersSkeleton
                        .padding(.top, 16)
                }

                // 1. Last Minute
                if !lastMinuteOffers.isEmpty {
                    lastMinuteSection
                        .padding(.top, 16)
                }

                // 2. Best for You
                if !bestForYouOffers.isEmpty {
                    bestForYouSection
                        .padding(.top, 24)
                }

                // 3. All Offers
                if !allRegularOffers.isEmpty {
                    allOffersSection
                        .padding(.top, 28)
                }

                // 4. Empty state
                if store.offers.isEmpty && store.hasLoaded {
                    emptyState
                        .padding(.top, 60)
                }

                Color.clear.frame(height: 100)
            }
        }
        .refreshable { await store.load() }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationDestination(for: Offer.self) { offer in
            OfferDetailView(offer: offer, isBusiness: isBusiness)
        }
        .onChange(of: store.offers) { _, newOffers in
            allOffers = newOffers
        }
        .task {
            await store.loadIfNeeded()
            allOffers = store.offers
        }
    }

    // MARK: - Last Minute Section

    private var lastMinuteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("\u{1F525}")
                    .font(.system(size: 16))
                Text("Last Minute")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(lastMinuteOffers) { offer in
                        NavigationLink(value: offer) {
                            lastMinuteCard(offer)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func lastMinuteCard(_ offer: Offer) -> some View {
        ZStack(alignment: .bottom) {
            offerPhoto(offer)
                .frame(width: 240, height: 300)

            // Rich gradient — deeper, more cinematic
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.35),
                    .init(color: .black.opacity(0.55), location: 0.6),
                    .init(color: .black.opacity(0.92), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top badges — glass style
            VStack {
                HStack(alignment: .top) {
                    typeBadge(offer.type)
                    Spacer()
                    if let expiry = offer.expiryDate {
                        CountdownPill(deadline: expiry)
                    }
                }
                .padding(12)
                Spacer()
            }

            // Bottom content — premium layout
            VStack(alignment: .leading, spacing: 8) {
                Spacer()

                Text(offer.title.replacingOccurrences(of: "[LAST MINUTE] ", with: ""))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                Text(offer.rewardSummary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .lineLimit(1)

                if offer.slotsRemaining > 0 && offer.slotsRemaining <= 5 {
                    slotsBadge(offer.slotsRemaining)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(width: 240, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    // MARK: - Best For You Section

    private var bestForYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Best for You")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Curated opportunities in Bali")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {
                    showAllBestForYou = true
                } label: {
                    Text("See All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(bestForYouOffers) { offer in
                        NavigationLink(value: offer) {
                            bestForYouCard(offer)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showAllBestForYou) {
            allBestForYouSheet
        }
    }

    private var allBestForYouSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredOffers.filter { !$0.isLastMinute }) { offer in
                        NavigationLink(value: offer) {
                            allOfferRow(offer)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Best for You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAllBestForYou = false }
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
        }
    }

    private func bestForYouCard(_ offer: Offer) -> some View {
        ZStack(alignment: .bottom) {
            offerPhoto(offer)
                .frame(width: 240, height: 300)

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.35),
                    .init(color: .black.opacity(0.55), location: 0.6),
                    .init(color: .black.opacity(0.92), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top: type pill left + countdown right (matching main hero cards)
            VStack {
                HStack(alignment: .top) {
                    typeBadge(offer.type)
                    Spacer()
                    if let expiry = offer.expiryDate {
                        CountdownPill(deadline: expiry)
                    }
                }
                .padding(12)
                Spacer()
            }

            // Bottom content
            VStack(alignment: .leading, spacing: 6) {
                Spacer()

                // Creator row
                HStack(spacing: 6) {
                    creatorAvatar(offer.creator, size: 20)
                    Text(offer.creator.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }

                Text(offer.title.replacingOccurrences(of: "[LAST MINUTE] ", with: ""))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                Text(offer.rewardSummary)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .lineLimit(1)

                if offer.slotsRemaining > 0 && offer.slotsRemaining <= 5 {
                    slotsBadge(offer.slotsRemaining)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(width: 240, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }

    // MARK: - All Offers Section

    private var allOffersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Offers")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(allRegularOffers.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))

                Spacer()
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 12) {
                ForEach(allRegularOffers) { offer in
                    NavigationLink(value: offer) {
                        allOfferCard(offer)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func allOfferRow(_ offer: Offer) -> some View {
        allOfferCard(offer)
    }

    private func allOfferCard(_ offer: Offer) -> some View {
        // Large Hero Card — photo на весь фон (~340pt), градиент, Barter/Paid
        // pill + deadline countdown сверху, внизу business name + title + reward.
        ZStack(alignment: .topLeading) {
            offerPhoto(offer)
                .frame(height: 340)
                .frame(maxWidth: .infinity)
                .clipped()

            // Deep cinematic gradient — сильный внизу, лёгкий сверху для badges
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.35), location: 0.0),
                    .init(color: .clear, location: 0.18),
                    .init(color: .clear, location: 0.45),
                    .init(color: .black.opacity(0.6), location: 0.72),
                    .init(color: .black.opacity(0.95), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Top row: type pill (left) + deadline (right)
            VStack {
                HStack(alignment: .top) {
                    typeBadge(offer.type)
                    Spacer()
                    if let expiry = offer.expiryDate {
                        CountdownPill(deadline: expiry)
                    }
                }
                .padding(14)
                Spacer()
            }

            // Bottom content
            VStack(alignment: .leading, spacing: 10) {
                Spacer()

                // Creator row — mini avatar + business name
                HStack(spacing: 8) {
                    creatorAvatar(offer.creator, size: 28)
                    Text(offer.creator.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                    if let district = offer.creator.district {
                        Text("·")
                            .foregroundStyle(.white.opacity(0.4))
                        Text(district)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Text(offer.title.replacingOccurrences(of: "[LAST MINUTE] ", with: ""))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                HStack(spacing: 10) {
                    Text(offer.rewardSummary)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .lineLimit(1)

                    if offer.slotsRemaining > 0 && offer.slotsRemaining <= 5 {
                        slotsBadge(offer.slotsRemaining)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(height: 340)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
    }

    // MARK: - Shared Components

    @ViewBuilder
    private func offerPhoto(_ offer: Offer) -> some View {
        if let url = offer.coverURL {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    cardPlaceholder(offer)
                }
            }
        } else {
            cardPlaceholder(offer)
        }
    }

    private func cardPlaceholder(_ offer: Offer) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1A2E13), Color(hex: 0x101314)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(String(offer.creator.name.prefix(1)).uppercased())
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.25))
        }
    }

    private func creatorAvatar(_ creator: UserProfile, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: size, height: size)

            if let url = creator.photoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    } else {
                        initials(creator.name, size: size)
                    }
                }
            } else {
                initials(creator.name, size: size)
            }
        }
    }

    private func initials(_ name: String, size: CGFloat) -> some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(MatchaTokens.Colors.accent)
    }

    private func typeBadge(_ type: CollaborationType) -> some View {
        Text(type.title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(type == .barter ? MatchaTokens.Colors.background : MatchaTokens.Colors.background)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                type == .barter ? MatchaTokens.Colors.accent : MatchaTokens.Colors.warning,
                in: Capsule()
            )
    }

    private func slotsBadge(_ remaining: Int) -> some View {
        Text("\(remaining) left")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.5), in: Capsule())
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            }
    }

    // MARK: - Skeleton Loading

    private var offersSkeleton: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 120, height: 18)
                .padding(.horizontal, 20)

            // Card skeletons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 240, height: 300)
                            .overlay {
                                VStack(alignment: .leading, spacing: 10) {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 16)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 140, height: 12)
                                }
                                .padding(14)
                            }
                    }
                }
                .padding(.horizontal, 20)
            }

            // All offers skeleton
            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 160)
                }
            }
            .padding(.horizontal, 20)
        }
        .redacted(reason: .placeholder)
    }

    // MARK: - Error + Empty

    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 13))
            Text("Connection error")
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Button("Retry") { Task { await store.load() } }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "tag.slash")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.15))

            Text("No offers yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Text("Check back soon")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Store

@MainActor
@Observable
final class OffersStore {
    private let repository: any MatchaRepository

    var offers: [Offer] = []
    var error: NetworkError?
    var hasLoaded = false
    var isLoading = false

    init(repository: any MatchaRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load(filters: OfferFilterParams = OfferFilterParams()) async {
        error = nil
        isLoading = true
        defer { isLoading = false; hasLoaded = true }
        do {
            offers = try await repository.fetchOffers(filters: filters)
        } catch let networkError as NetworkError {
            self.error = networkError
            offers = []
        } catch {
            self.error = .networkError(error)
            offers = []
        }
    }
}

// MARK: - Brand Profile

struct BrandProfile: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let photoURL: URL?
    let hasBlueCheck: Bool

    init(id: UUID = UUID(), name: String, category: String, photoURL: URL? = nil, hasBlueCheck: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.photoURL = photoURL
        self.hasBlueCheck = hasBlueCheck
    }
}

// MARK: - Countdown Pill

private struct CountdownPill: View {
    let deadline: Date
    @State private var remaining: TimeInterval = 0

    var body: some View {
        Text(formatted)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.7), in: Capsule())
            .onAppear { remaining = deadline.timeIntervalSinceNow }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                remaining = deadline.timeIntervalSinceNow
            }
    }

    private var formatted: String {
        let r = max(0, remaining)
        let hours = Int(r) / 3600
        let minutes = (Int(r) % 3600) / 60
        let seconds = Int(r) % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds) }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        OffersView(repository: MockMatchaRepository())
    }
    .preferredColorScheme(.dark)
}
