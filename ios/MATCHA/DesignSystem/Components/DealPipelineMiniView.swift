import SwiftUI

// MARK: - DealPipelineMiniView
/// Pipeline for chat list rows. Visually identical to DealPipelineView(compact: false)
/// but WITHOUT header, card background, info row, and action footer.
/// Accepts only a DealStatus (not a full Deal).

struct DealPipelineMiniView: View {
    let status: DealStatus
    var showCTA: Bool = false

    // Sizes matching DealPipelineView(compact: false) per spec
    private let circleSize: CGFloat = 24
    private let lineHeight: CGFloat = 3
    private let labelFont: Font = .system(size: 10, weight: .semibold)
    private let checkmarkFont: Font = .system(size: 11, weight: .bold)

    private static let stages: [DealStatus] = [.draft, .confirmed, .visited, .reviewed]

    private var currentIndex: Int {
        switch status {
        case .cancelled: return -1
        case .noShow: return Self.stages.firstIndex(of: .confirmed) ?? 1
        default: return Self.stages.firstIndex(of: status) ?? -1
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 6) {
                pipelineRow
                stageLabelsRow
            }
            .frame(maxWidth: .infinity)

            if showCTA {
                HStack(spacing: 3) {
                    Text("Your move")
                        .font(.system(size: 11, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(MatchaTokens.Colors.accent)
                .fixedSize()
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Pipeline Row

    private var pipelineRow: some View {
        GeometryReader { geo in
            let count = CGFloat(Self.stages.count)
            let totalWidth = geo.size.width
            let spacing = (totalWidth - circleSize * count) / (count - 1)

            ZStack(alignment: .leading) {
                ForEach(0..<Self.stages.count - 1, id: \.self) { i in
                    let xStart = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2
                    let xEnd = circleSize * CGFloat(i + 1) + spacing * CGFloat(i + 1) + circleSize / 2
                    let isCompleted = i < currentIndex

                    Rectangle()
                        .fill(isCompleted ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline)
                        .frame(width: xEnd - xStart, height: lineHeight)
                        .position(x: (xStart + xEnd) / 2, y: circleSize / 2)
                }

                ForEach(0..<Self.stages.count, id: \.self) { i in
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

        ZStack {
            if isCompleted {
                Circle()
                    .fill(MatchaTokens.Colors.accent)
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: "checkmark")
                    .font(checkmarkFont)
                    .foregroundStyle(MatchaTokens.Colors.background)
            } else if isCurrent {
                Circle()
                    .fill(MatchaTokens.Colors.background)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle().strokeBorder(MatchaTokens.Colors.accent, lineWidth: 2)
                    )
                    .shadow(color: MatchaTokens.Colors.accent.opacity(0.6), radius: 8)
                Circle()
                    .fill(MatchaTokens.Colors.accent)
                    .frame(width: circleSize * 0.35, height: circleSize * 0.35)
            } else {
                Circle()
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle().strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1.5)
                    )
            }
        }
    }

    // MARK: - Stage Labels

    private var stageLabelsRow: some View {
        GeometryReader { geo in
            let count = CGFloat(Self.stages.count)
            let totalWidth = geo.size.width
            let spacing = (totalWidth - circleSize * count) / (count - 1)

            ZStack(alignment: .leading) {
                ForEach(0..<Self.stages.count, id: \.self) { i in
                    let xPos = circleSize * CGFloat(i) + spacing * CGFloat(i) + circleSize / 2
                    let isCompleted = i < currentIndex
                    let isCurrent = i == currentIndex

                    Text(Self.stages[i].title)
                        .font(labelFont)
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
}
