import SwiftUI

// MARK: - OfferFilterState

struct OfferFilterState: Equatable {
    var collabType: CollaborationType? = nil
    var selectedNiches: Set<String> = []
    var lastMinuteOnly: Bool = false

    var isActive: Bool {
        collabType != nil || !selectedNiches.isEmpty || lastMinuteOnly
    }
}

// MARK: - OfferFilterView

struct OfferFilterView: View {
    @Binding var filterState: OfferFilterState
    var allOffers: [Offer] = []
    var onApply: ((OfferFilterState) -> Void)? = nil

    @State private var draft: OfferFilterState
    @Environment(\.dismiss) private var dismiss

    private let allNiches = [
        "Food", "Travel", "Lifestyle", "Fashion", "Beauty",
        "Fitness", "Tech", "Music", "Art", "Photography",
        "Business", "Health", "Gaming", "Cooking", "Sports",
    ]

    init(
        filterState: Binding<OfferFilterState>,
        allOffers: [Offer] = [],
        onApply: ((OfferFilterState) -> Void)? = nil
    ) {
        self._filterState = filterState
        self._draft = State(initialValue: filterState.wrappedValue)
        self.allOffers = allOffers
        self.onApply = onApply
    }

    private var matchingCount: Int {
        var result = allOffers
        if let type = draft.collabType {
            result = result.filter { $0.type == type }
        }
        if !draft.selectedNiches.isEmpty {
            let selected = Set(draft.selectedNiches.map { $0.lowercased() })
            result = result.filter { offer in
                var offerNiches = Set(offer.preferredNiches.map { $0.lowercased() })
                if let p = offer.preferredNiche { offerNiches.insert(p.lowercased()) }
                return !selected.isDisjoint(with: offerNiches)
            }
        }
        if draft.lastMinuteOnly {
            result = result.filter(\.isLastMinute)
        }
        return result.count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MatchaTokens.Spacing.large) {
                    typeSection
                    lastMinuteSection
                    nichesSection
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.top, MatchaTokens.Spacing.large)
                .padding(.bottom, 120)
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Filter Offers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        withAnimation(MatchaTokens.Animations.buttonPress) {
                            draft = OfferFilterState()
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(draft.isActive ? MatchaTokens.Colors.danger : MatchaTokens.Colors.textSecondary.opacity(0.4))
                    .disabled(!draft.isActive)
                }
            }
            .overlay(alignment: .bottom) { bottomBar }
        }
    }

    // MARK: - Type Section

    private var typeSection: some View {
        filterCard(title: "Collaboration Type") {
            VStack(spacing: 0) {
                // All
                typeRow(
                    icon: "sparkle",
                    color: MatchaTokens.Colors.textSecondary,
                    title: "All Types",
                    subtitle: "Show every collaboration type",
                    selected: draft.collabType == nil,
                    action: { draft.collabType = nil }
                )

                filterDivider

                ForEach([CollaborationType.barter, .paid], id: \.self) { type in
                    typeRow(
                        icon: typeIcon(type),
                        color: typeColor(type),
                        title: type.title,
                        subtitle: typeSubtitle(type),
                        selected: draft.collabType == type,
                        action: { draft.collabType = type }
                    )

                    if type != .paid {
                        filterDivider
                    }
                }
            }
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func typeRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { withAnimation(MatchaTokens.Animations.buttonPress) { action() } }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(
                            selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                            lineWidth: selected ? 0 : 1.5
                        )
                        .frame(width: 22, height: 22)

                    if selected {
                        Circle()
                            .fill(MatchaTokens.Colors.accent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(MatchaTokens.Colors.background)
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Last Minute Toggle

    private var lastMinuteSection: some View {
        filterCard(title: "Availability") {
            Button(action: {
                withAnimation(MatchaTokens.Animations.buttonPress) {
                    draft.lastMinuteOnly.toggle()
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(MatchaTokens.Colors.warning.opacity(0.12))
                            .frame(width: 34, height: 34)
                        Image(systemName: "bolt.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.warning)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last Minute Only")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        Text("Expiring within 48 hours")
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }

                    Spacer()

                    // Custom toggle visual
                    ZStack {
                        Capsule()
                            .fill(draft.lastMinuteOnly ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated)
                            .frame(width: 44, height: 26)
                            .overlay(Capsule().strokeBorder(
                                draft.lastMinuteOnly ? Color.clear : MatchaTokens.Colors.outline,
                                lineWidth: 1
                            ))

                        Circle()
                            .fill(draft.lastMinuteOnly ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                            .frame(width: 20, height: 20)
                            .offset(x: draft.lastMinuteOnly ? 9 : -9)
                    }
                }
                .padding(.horizontal, MatchaTokens.Spacing.medium)
                .padding(.vertical, 14)
                .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Niches Section

    private var nichesSection: some View {
        filterCard(title: "Blogger Niche") {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                HStack {
                    Text("Show offers matching bloggers in these niches")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.7))
                    Spacer()
                    if !draft.selectedNiches.isEmpty {
                        Text("\(draft.selectedNiches.count) selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                }

                OfferNicheFlowLayout(spacing: 8) {
                    ForEach(allNiches, id: \.self) { niche in
                        let isSelected = draft.selectedNiches.contains(niche)
                        Button(action: {
                            withAnimation(MatchaTokens.Animations.buttonPress) {
                                if isSelected {
                                    draft.selectedNiches.remove(niche)
                                } else {
                                    draft.selectedNiches.insert(niche)
                                }
                            }
                        }) {
                            HStack(spacing: 5) {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                }
                                Text(niche)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(isSelected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color.clear : MatchaTokens.Colors.outline,
                                    lineWidth: 1
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(MatchaTokens.Colors.outline)

            HStack(spacing: MatchaTokens.Spacing.small) {
                Button("Reset") {
                    withAnimation { draft = OfferFilterState() }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .frame(width: 80)
                .padding(.vertical, 18)
                .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                )

                Button(action: applyFilters) {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.body.weight(.semibold))
                        Text(draft.isActive ? "~\(matchingCount) offers" : "Show All")
                            .font(.headline)
                    }
                    .foregroundStyle(MatchaTokens.Colors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.medium)
            .background(MatchaTokens.Colors.background)
        }
    }

    // MARK: - Helpers

    private func applyFilters() {
        filterState = draft
        onApply?(draft)
        dismiss()
    }

    private var filterDivider: some View {
        Divider()
            .background(MatchaTokens.Colors.outline)
            .padding(.leading, 62)
    }

    private func filterCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)
            content()
        }
    }

    private func typeIcon(_ type: CollaborationType) -> String {
        switch type {
        case .paid:   return "dollarsign.circle.fill"
        case .barter: return "arrow.trianglehead.2.counterclockwise.rotate.90"
        case .both:   return "plus.circle.fill"
        }
    }

    private func typeColor(_ type: CollaborationType) -> Color {
        switch type {
        case .paid:   return MatchaTokens.Colors.success
        case .barter: return MatchaTokens.Colors.warning
        case .both:   return MatchaTokens.Colors.accent
        }
    }

    private func typeSubtitle(_ type: CollaborationType) -> String {
        switch type {
        case .paid:   return "Monetary compensation only"
        case .barter: return "Exchange services or products"
        case .both:   return "Open to either arrangement"
        }
    }
}

// MARK: - OfferNicheFlowLayout

private struct OfferNicheFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        return CGSize(width: width, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OfferFilterView(filterState: .constant(OfferFilterState()))
        .preferredColorScheme(.dark)
}
