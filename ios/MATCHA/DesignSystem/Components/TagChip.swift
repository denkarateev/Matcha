import SwiftUI

// MARK: - MatchaTagChip

/// Selectable pill chip for niche/category tags.
/// Rename: uses `MatchaTagChip` to avoid collision with any existing TagChip name.
struct MatchaTagChip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) { chipContent }
                    .buttonStyle(TagChipButtonStyle())
            } else {
                chipContent
            }
        }
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var chipContent: some View {
        HStack(spacing: 5) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(title)
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(isSelected ? .black : MatchaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, MatchaTokens.Spacing.xSmall + 2)
        .background(
            Capsule().fill(isSelected ? MatchaTokens.Colors.accent : Color.white.opacity(0.10))
        )
        .overlay(
            Capsule().strokeBorder(
                isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                lineWidth: 1
            )
        )
        .animation(MatchaTokens.Animations.buttonPress, value: isSelected)
    }
}

private struct TagChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(MatchaTokens.Animations.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - FlowLayout (wrapping tag grid)

/// A layout that wraps chips left-to-right, breaking to a new row as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - TagChipGrid (convenience wrapper)

struct TagChipGrid: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    var spacing: CGFloat = 8

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(tags, id: \.self) { tag in
                MatchaTagChip(
                    title: tag,
                    isSelected: selectedTags.contains(tag)
                ) {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("TagChipGrid") {
    @Previewable @State var selected: Set<String> = ["Food & Beverage", "Travel"]

    let niches = [
        "Food & Beverage", "Travel", "Yoga", "Fitness",
        "Fashion", "Beauty", "Wellness", "Photography",
        "Nightlife", "Music", "Art & Design", "Sports"
    ]

    VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
        Text("Select your niches")
            .font(MatchaTokens.Typography.headline)
            .foregroundStyle(MatchaTokens.Colors.textPrimary)

        TagChipGrid(tags: niches, selectedTags: $selected)

        Text("Selected: \(selected.sorted().joined(separator: ", "))")
            .font(MatchaTokens.Typography.caption)
            .foregroundStyle(MatchaTokens.Colors.textSecondary)
    }
    .padding(MatchaTokens.Spacing.large)
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
