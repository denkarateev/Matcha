import SwiftUI

/// Instagram-style tab bar: icons only, outline → fill on selection,
/// the tuju dot in the center and the user's avatar as the Profile tab.
/// Sits over content via `.safeAreaInset(edge: .bottom)`.
struct TujuTabBar: View {
    @Binding var selection: AppTab
    var avatarURL: URL?

    var body: some View {
        HStack(spacing: 0) {
            symbolTab(.offers, outline: "tag", filled: "tag.fill")
            symbolTab(.likes, outline: "heart", filled: "heart.fill")
            dotTab
            symbolTab(.chats, outline: "bubble.left", filled: "bubble.left.fill")
            avatarTab
        }
        .frame(height: 54)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.35))
                .overlay(alignment: .top) {
                    Divider().background(MatchaTokens.Colors.outline.opacity(0.5))
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selection)
    }

    private func symbolTab(_ tab: AppTab, outline: String, filled: String) -> some View {
        tabButton(tab) { selected in
            Image(systemName: selected ? filled : outline)
                .font(.system(size: 23, weight: .regular))
                .foregroundStyle(selected ? .white : MatchaTokens.Colors.textMuted)
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
                        .frame(width: 22, height: 22)
                        .shadow(color: MatchaTokens.Colors.accentGlow.opacity(0.7), radius: 8)
                } else {
                    Circle()
                        .strokeBorder(MatchaTokens.Colors.textMuted, lineWidth: 2.5)
                        .frame(width: 22, height: 22)
                    Circle()
                        .fill(MatchaTokens.Colors.textMuted)
                        .frame(width: 6, height: 6)
                }
            }
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
            .frame(width: 26, height: 26)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(
                    selected ? Color.white : Color.clear,
                    lineWidth: 1.5
                )
            }
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle().fill(MatchaTokens.Colors.elevated)
            Image(systemName: "person.fill")
                .font(.system(size: 13))
                .foregroundStyle(MatchaTokens.Colors.textMuted)
        }
    }

    private func tabButton(_ tab: AppTab, @ViewBuilder icon: @escaping (Bool) -> some View) -> some View {
        Button {
            selection = tab
        } label: {
            icon(selection == tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
