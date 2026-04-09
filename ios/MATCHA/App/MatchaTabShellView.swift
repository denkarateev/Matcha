import Observation
import SwiftUI

struct MatchaTabShellView: View {
    @Bindable var appState: AppState
    let environment: AppEnvironment

    @Environment(\.scenePhase) private var scenePhase
    @State private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineBanner = false

    // Return experience (spec 20)
    @State private var showReturnSheet = false
    @State private var returnMetrics = ReturnMetrics()
    @AppStorage("matcha_last_active_date") private var lastActiveDateInterval: Double = Date().timeIntervalSince1970

    var body: some View {
        VStack(spacing: 0) {
            if showOfflineBanner {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            TabView(selection: $appState.selectedTab) {
                // Tab 1: Offers
                NavigationStack {
                    OffersAndDealsView(
                        currentUser: appState.currentUser,
                        repository: environment.repository
                    )
                }
                .tabItem {
                    Label("Offers", systemImage: "tag.fill")
                }
                .tag(AppTab.offers)

                // Tab 2: Activity
                NavigationStack {
                    NotificationsView(
                        currentUser: appState.currentUser,
                        repository: environment.repository
                    )
                }
                .tabItem {
                    Label("Activity", systemImage: "heart.fill")
                }
                .tag(AppTab.notifications)

                // Tab 3: Match Feed (center)
                NavigationStack {
                    MatchFeedView(repository: environment.repository)
                }
                .tabItem {
                    Label("Match", systemImage: "leaf.fill")
                }
                .tag(AppTab.match)

                // Tab 4: Chats
                NavigationStack {
                    ChatsView(repository: environment.repository)
                }
                .tabItem {
                    Label("Chats", systemImage: "bubble.fill")
                }
                .tag(AppTab.chats)

                // Tab 5: Profile
                NavigationStack {
                    ProfileView(
                        currentUser: appState.currentUser,
                        repository: environment.repository,
                        onProfileSaved: { updatedUser in
                            appState.currentUser = updatedUser
                        },
                        onSignOut: { appState.signOut() }
                    )
                    .id(appState.currentUser)
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
            }
            .tint(MatchaTokens.Colors.accent)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
        }
        .animation(.easeInOut(duration: 0.3), value: showOfflineBanner)
        .onChange(of: networkMonitor.isConnected) { _, connected in
            if connected {
                showOfflineBanner = false
            } else {
                // Delay showing banner to avoid flash on app start
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if !networkMonitor.isConnected {
                        showOfflineBanner = true
                    }
                }
            }
        }
        .onAppear {
            checkReturnExperience()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshCurrentUserIfNeeded() }
        }
        .onChange(of: appState.selectedTab) { _, selectedTab in
            guard selectedTab == .profile || selectedTab == .match else { return }
            Task { await refreshCurrentUserIfNeeded() }
        }
        .sheet(isPresented: $showReturnSheet) {
            ReturnExperienceSheet(
                metrics: returnMetrics,
                onAction: { action in
                    handleReturnAction(action)
                },
                onDismiss: {
                    updateLastActiveDate()
                }
            )
        }
    }

    // MARK: - Return Experience (spec 20)

    private func refreshCurrentUserIfNeeded() async {
        guard appState.isAuthenticated, !appState.isLoadingUser else { return }
        await appState.loadCurrentUser(repository: environment.repository)
    }

    private func checkReturnExperience() {
        let lastActiveDate = Date(timeIntervalSince1970: lastActiveDateInterval)
        let daysSinceActive = Calendar.current.dateComponents(
            [.day],
            from: lastActiveDate,
            to: Date()
        ).day ?? 0

        guard daysSinceActive >= 3 else {
            updateLastActiveDate()
            return
        }

        // TODO: Fetch real metrics from API
        // For now, generate plausible placeholder metrics
        let metrics = ReturnMetrics(
            newLikes: Int.random(in: 0...12),
            newOffers: Int.random(in: 0...6),
            newProfiles: Int.random(in: 0...15)
        )

        guard metrics.hasAnyActivity else {
            updateLastActiveDate()
            return
        }

        returnMetrics = metrics
        showReturnSheet = true
        updateLastActiveDate()
    }

    private func updateLastActiveDate() {
        lastActiveDateInterval = Date().timeIntervalSince1970
    }

    private func handleReturnAction(_ action: ReturnAction) {
        switch action {
        case .seeLikes:
            appState.selectedTab = .activity
        case .openOffers:
            appState.selectedTab = .offers
        case .startMatching:
            appState.selectedTab = .match
        }
    }
}
