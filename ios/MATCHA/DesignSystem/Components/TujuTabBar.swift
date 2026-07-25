import SwiftUI

/// tuju tab bar: icon + label per tab, outline → fill on selection,
/// the tuju dot in the center and the user's avatar as the Profile tab.
/// Attached via `.safeAreaInset(edge: .bottom)`; `safeAreaPadding` makes the
/// reserved height cover the home-indicator strip too, so screen content
/// never slides underneath the glass.
struct TujuTabBar: View {
    @Binding var selection: AppTab
    var avatarURL: URL?

    private let iconSize: CGFloat = 22

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            symbolTab(.offers, outline: "tag", filled: "tag.fill")
            symbolTab(.likes, outline: "heart", filled: "heart.fill")
            dotTab
            symbolTab(.chats, outline: "bubble.left", filled: "bubble.left.fill")
            avatarTab
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(height: 62, alignment: .top)
        .background {
            // Floating liquid glass: translucent, rounded, no edge-to-edge slab.
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MatchaTokens.Colors.glassHighlight, .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.glassBorder, lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.45), radius: 18, y: 8)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selection)
    }

    private func symbolTab(_ tab: AppTab, outline: String, filled: String) -> some View {
        tabButton(tab) { selected in
            Image(systemName: selected ? filled : outline)
                .font(.system(size: iconSize, weight: .regular))
                .frame(height: iconSize + 2)
                .symbolEffect(.bounce, value: selected)
        }
    }

    /// Center tab — the tuju dot: ring when idle, glowing accent dot when active.
    private var dotTab: some View {
        tabButton(.match) { selected in
            ZStack {
                if selected {
                    Circle()
                        .fill(MatchaTokens.Colors.accent)
                        .frame(width: 21, height: 21)
                        .shadow(color: MatchaTokens.Colors.accentGlow.opacity(0.7), radius: 8)
                } else {
                    Circle()
                        .strokeBorder(MatchaTokens.Colors.textMuted, lineWidth: 2.2)
                        .frame(width: 21, height: 21)
                    Circle()
                        .fill(MatchaTokens.Colors.textMuted)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: iconSize + 2)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: selected)
        }
    }

    private var avatarTab: some View {
        tabButton(.profile) { selected in
            Group {
                if let avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            avatarFallback
                        }
                    }
                } else {
                    avatarFallback
                }
            }
            .frame(width: 23, height: 23)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(selected ? Color.white : .clear, lineWidth: 1.5)
            }
            .frame(height: iconSize + 2)
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle().fill(MatchaTokens.Colors.elevated)
            Image(systemName: "person.fill")
                .font(.system(size: 12))
                .foregroundStyle(MatchaTokens.Colors.textMuted)
        }
    }

    private func tabButton(_ tab: AppTab, @ViewBuilder icon: @escaping (Bool) -> some View) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 3) {
                icon(selected)
                Text(tab.title)
                    .font(.system(size: 10, weight: selected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(selected ? Color.white : MatchaTokens.Colors.textMuted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}

#Preview {
    @Previewable @State var tab: AppTab = .match
    return VStack {
        Spacer()
        TujuTabBar(selection: $tab, avatarURL: nil)
    }
    .background(MatchaTokens.Colors.background)
    .preferredColorScheme(.dark)
}
