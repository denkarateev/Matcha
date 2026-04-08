import SwiftUI

// MARK: - FeedFilterState

struct FeedFilterState: Equatable {
    var roleFilter: FeedRoleFilter = .all
    var selectedNiches: Set<String> = []
    var district: String = ""
    var minimumFollowers: Double = 0
    var collaborationType: CollaborationType? = nil

    var isActive: Bool {
        roleFilter != .all
            || !selectedNiches.isEmpty
            || !district.isEmpty
            || minimumFollowers > 0
            || collaborationType != nil
    }
}

enum FeedRoleFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case creators = "Creators"
    case businesses = "Businesses"

    var id: String { rawValue }
}

// MARK: - FeedFilterView

struct FeedFilterView: View {
    @Binding var filterState: FeedFilterState
    var onApply: ((FeedFilterState) -> Void)? = nil

    @State private var draft: FeedFilterState
    @Environment(\.dismiss) private var dismiss

    private let allNiches = [
        "Food", "Travel", "Lifestyle", "Fashion", "Beauty",
        "Fitness", "Tech", "Music", "Art", "Photography",
        "Business", "Health", "Gaming", "Cooking", "Sports",
    ]

    private let followerStops: [Double] = [0, 1_000, 5_000, 10_000, 50_000, 100_000, 500_000]

    init(filterState: Binding<FeedFilterState>, onApply: ((FeedFilterState) -> Void)? = nil) {
        self._filterState = filterState
        self._draft = State(initialValue: filterState.wrappedValue)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MatchaTokens.Spacing.large) {
                    roleSection
                    nichesSection
                    locationSection
                    followersSection
                    collabTypeSection
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.top, MatchaTokens.Spacing.large)
                .padding(.bottom, 100)
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Filter")
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
                    Button("Reset") { draft = FeedFilterState() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(draft.isActive ? MatchaTokens.Colors.danger : MatchaTokens.Colors.textSecondary.opacity(0.4))
                        .disabled(!draft.isActive)
                }
            }
            .overlay(alignment: .bottom) { bottomBar }
        }
    }

    // MARK: - Role Filter

    private var roleSection: some View {
        filterCard(title: "Show Me") {
            HStack(spacing: 8) {
                ForEach(FeedRoleFilter.allCases) { role in
                    let selected = draft.roleFilter == role
                    Button(action: {
                        withAnimation(MatchaTokens.Animations.buttonPress) {
                            draft.roleFilter = role
                        }
                    }) {
                        Text(role.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Niches

    private var nichesSection: some View {
        filterCard(title: "Niches") {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                if !draft.selectedNiches.isEmpty {
                    Text("\(draft.selectedNiches.count) selected")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }

                FlowLayoutFilter(spacing: 8) {
                    ForEach(allNiches, id: \.self) { niche in
                        let selected = draft.selectedNiches.contains(niche)
                        Button(action: {
                            withAnimation(MatchaTokens.Animations.buttonPress) {
                                if selected {
                                    draft.selectedNiches.remove(niche)
                                } else {
                                    draft.selectedNiches.insert(niche)
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                }
                                Text(niche)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(selected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    selected ? Color.clear : MatchaTokens.Colors.outline,
                                    lineWidth: 1
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - District Picker

    private let baliDistricts = [
        "All Districts", "Canggu", "Seminyak", "Ubud",
        "Uluwatu", "Sanur", "Denpasar",
    ]

    private var locationSection: some View {
        filterCard(title: "District") {
            FlowLayoutFilter(spacing: 8) {
                ForEach(baliDistricts, id: \.self) { district in
                    let isAll = district == "All Districts"
                    let selected = isAll ? draft.district.isEmpty : draft.district == district
                    Button {
                        withAnimation(MatchaTokens.Animations.buttonPress) {
                            draft.district = isAll ? "" : district
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if !isAll {
                                Image(systemName: "mappin")
                                    .font(.caption2)
                            }
                            Text(district)
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(selected ? .black : MatchaTokens.Colors.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                            in: Capsule()
                        )
                    }
                }
            }
        }
    }

    // MARK: - Audience Tier Picker

    private struct AudienceTier: Identifiable {
        let id: String
        let label: String
        let range: String
        let cardLabel: String
        let minFollowers: Double

        static let all: [AudienceTier] = [
            .init(id: "any", label: "Any", range: "All sizes", cardLabel: "Any", minFollowers: 0),
            .init(id: "nano", label: "Nano", range: "1K – 10K", cardLabel: "✓ 5K", minFollowers: 1_000),
            .init(id: "micro", label: "Micro", range: "10K – 100K", cardLabel: "✓ 25K", minFollowers: 10_000),
            .init(id: "mid", label: "Mid", range: "100K – 500K", cardLabel: "✓ 250K", minFollowers: 100_000),
            .init(id: "macro", label: "Macro", range: "500K+", cardLabel: "✓ 750K", minFollowers: 500_000),
        ]
    }

    private var selectedTierId: String {
        let v = draft.minimumFollowers
        if v >= 500_000 { return "macro" }
        if v >= 100_000 { return "mid" }
        if v >= 10_000 { return "micro" }
        if v >= 1_000 { return "nano" }
        return "any"
    }

    private var followersSection: some View {
        filterCard(title: "Audience Tier") {
            VStack(spacing: 10) {
                ForEach(AudienceTier.all) { tier in
                    let selected = selectedTierId == tier.id
                    Button {
                        withAnimation(MatchaTokens.Animations.buttonPress) {
                            draft.minimumFollowers = tier.minFollowers
                        }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tier.label)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(selected ? .black : MatchaTokens.Colors.textPrimary)
                                Text(tier.range)
                                    .font(.caption)
                                    .foregroundStyle(selected ? .black.opacity(0.7) : MatchaTokens.Colors.textSecondary)
                            }

                            Spacer()

                            Text(tier.cardLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selected ? .black.opacity(0.6) : MatchaTokens.Colors.textSecondary.opacity(0.5))

                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Collab Type

    private var collabTypeSection: some View {
        filterCard(title: "Collaboration Type") {
            VStack(spacing: 0) {
                // "Any" option
                collabTypeRow(
                    icon: "sparkle",
                    color: MatchaTokens.Colors.textSecondary,
                    title: "Any Type",
                    subtitle: "Show all collaboration types",
                    selected: draft.collaborationType == nil,
                    action: { draft.collaborationType = nil }
                )

                filterDivider

                ForEach([CollaborationType.barter, .paid], id: \.self) { type in
                    collabTypeRow(
                        icon: collabIcon(type),
                        color: collabColor(type),
                        title: type.title,
                        subtitle: collabSubtitle(type),
                        selected: draft.collaborationType == type,
                        action: { draft.collaborationType = type }
                    )

                    if type != .paid {
                        filterDivider
                    }
                }
            }
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func collabTypeRow(
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

    private var filterDivider: some View {
        Divider()
            .background(MatchaTokens.Colors.outline)
            .padding(.leading, 62)
    }

    private func collabIcon(_ type: CollaborationType) -> String {
        switch type {
        case .paid:   return "dollarsign.circle.fill"
        case .barter: return "arrow.trianglehead.2.counterclockwise.rotate.90"
        case .both:   return "plus.circle.fill"
        }
    }

    private func collabColor(_ type: CollaborationType) -> Color {
        switch type {
        case .paid:   return MatchaTokens.Colors.success
        case .barter: return MatchaTokens.Colors.warning
        case .both:   return MatchaTokens.Colors.accent
        }
    }

    private func collabSubtitle(_ type: CollaborationType) -> String {
        switch type {
        case .paid:   return "Monetary compensation only"
        case .barter: return "Exchange services or products"
        case .both:   return "Open to either arrangement"
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(MatchaTokens.Colors.outline)

            HStack(spacing: MatchaTokens.Spacing.small) {
                Button("Reset") {
                    withAnimation { draft = FeedFilterState() }
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
                        Text(draft.isActive ? "Apply Filters" : "Show All")
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

    private func filterCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)

            content()
        }
    }
}

// MARK: - FlowLayoutFilter

/// Wrap layout for the filter pill tags.
private struct FlowLayoutFilter: Layout {
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
