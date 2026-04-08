import SwiftUI

// MARK: - Tab Definition

enum MatchaTab: Int, CaseIterable {
    case offers
    case activity
    case feed
    case chats
    case profile

    var icon: String {
        switch self {
        case .offers:   return "tag.fill"
        case .activity: return "bell.fill"
        case .feed:     return "leaf.fill"
        case .chats:    return "bubble.fill"
        case .profile:  return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .offers:   return "Offers"
        case .activity: return "Activity"
        case .feed:     return "Match"
        case .chats:    return "Chats"
        case .profile:  return "Profile"
        }
    }
}

// MARK: - MatchaTabBar

struct MatchaTabBar: View {
    @Binding var selectedTab: MatchaTab
    var badges: [MatchaTab: Int] = [:]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MatchaTab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, MatchaTokens.Spacing.small + 4)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab item

    private func tabItem(_ tab: MatchaTab) -> some View {
        let isActive = selectedTab == tab
        let badgeCount = badges[tab] ?? 0

        return Button {
            withAnimation(MatchaTokens.Animations.tabSwitch) {
                selectedTab = tab
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
                        .scaleEffect(isActive ? 1.12 : 1.0)

                    Text(tab.label)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(isActive ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
                        .opacity(isActive ? 1 : 0.7)
                }
                .animation(MatchaTokens.Animations.tabSwitch, value: isActive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MatchaTokens.Spacing.xSmall)

                if badgeCount > 0 {
                    badgePip(count: badgeCount)
                        .offset(x: -2, y: -2)
                }
            }
        }
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: selectedTab)
    }

    private func badgePip(count: Int) -> some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, count > 9 ? 5 : 4)
            .padding(.vertical, 2)
            .background(MatchaTokens.Colors.danger, in: Capsule())
            .fixedSize()
    }
}

// MARK: - MatchaTabView (full screen container)

/// Drop-in replacement for SwiftUI's TabView.
/// Wrap each screen in a tab and set the selectedTab binding.
///
/// Usage:
/// ```swift
/// @State private var tab: MatchaTab = .feed
///
/// MatchaTabView(selectedTab: $tab, badges: [.activity: 3, .chats: 7]) {
///     switch tab {
///     case .feed:     FeedScreen()
///     case .offers:   OffersScreen()
///     ...
///     }
/// }
/// ```
struct MatchaTabView<Content: View>: View {
    @Binding var selectedTab: MatchaTab
    var badges: [MatchaTab: Int] = [:]
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .bottom) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Extra bottom padding so content doesn't hide behind tab bar
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80)
                }

            MatchaTabBar(selectedTab: $selectedTab, badges: badges)
                .padding(.bottom, tabBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var tabBarBottomPadding: CGFloat {
        // Respect home indicator safe area
        (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0) + MatchaTokens.Spacing.small
    }
}

// MARK: - Preview

#Preview("MatchaTabBar") {
    @Previewable @State var tab: MatchaTab = .feed

    ZStack {
        MatchaTokens.Colors.background.ignoresSafeArea()

        VStack {
            Spacer()
            Text("Active: \(tab.label)")
                .font(MatchaTokens.Typography.headline)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Spacer()
            MatchaTabBar(
                selectedTab: $tab,
                badges: [.activity: 3, .chats: 12]
            )
            .padding(.bottom, 24)
        }
    }
    .preferredColorScheme(.dark)
}
