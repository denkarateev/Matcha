import Observation
import SwiftUI

// MARK: - NotificationsView

struct NotificationsView: View {
    let currentUser: UserProfile
    let repository: any MatchaRepository

    @State private var store: NotificationsStore
    @State private var showLikesPaywall = false
    @State private var selectedProfile: UserProfile?

    init(currentUser: UserProfile, repository: any MatchaRepository) {
        self.currentUser = currentUser
        self.repository = repository
        _store = State(initialValue: NotificationsStore(repository: repository))
    }

    private var shouldBlurLikes: Bool {
        currentUser.role == .business && currentUser.subscriptionPlan == .free
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let error = store.error, store.items.isEmpty {
                    errorBanner(error)
                        .padding(.horizontal, MatchaTokens.Spacing.large)
                        .padding(.top, 8)
                }

                if store.isLoading && store.items.isEmpty {
                    notificationsSkeleton
                        .padding(.top, 16)
                } else if store.items.isEmpty && store.hasLoaded {
                    emptyState
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(store.items) { item in
                            notificationRow(item)

                            if item.id != store.items.last?.id {
                                Divider()
                                    .background(MatchaTokens.Colors.outline)
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 100)
        }
        .refreshable { await store.load() }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Notifications")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            ToolbarItem(placement: .topBarTrailing) {
                bellBadge
            }
        }
        .toolbarBackground(Color(hex: 0x050505), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showLikesPaywall) {
            PaywallView(.blurredLikes)
        }
        .sheet(item: $selectedProfile) { profile in
            NavigationStack {
                ProfileDetailView(profile: profile)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task { await store.loadIfNeeded() }
    }

    // MARK: - Bell Badge

    private var bellBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            if store.unreadCount > 0 {
                Text(store.unreadCount > 99 ? "99+" : "\(store.unreadCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, store.unreadCount > 9 ? 5 : 4)
                    .padding(.vertical, 2)
                    .background(MatchaTokens.Colors.danger, in: Capsule())
                    .fixedSize()
                    .offset(x: 6, y: -4)
            }
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ item: NotificationItem) -> some View {
        Button {
            handleTap(item)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    avatarView(item)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                        }

                    // Type icon pip
                    typeIconPip(item.type)
                        .offset(x: 4, y: 4)
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    notificationText(item)

                    Text(item.timestamp)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textMuted)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, 14)
            .background(item.isRead ? Color.clear : MatchaTokens.Colors.accent.opacity(0.04))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Avatar

    @ViewBuilder
    private func avatarView(_ item: NotificationItem) -> some View {
        let shouldBlur = item.type == .likeReceived && shouldBlurLikes

        if let url = item.avatarURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                        .blur(radius: shouldBlur ? 8 : 0)
                default:
                    avatarPlaceholder(item.name)
                        .blur(radius: shouldBlur ? 8 : 0)
                }
            }
        } else {
            avatarPlaceholder(item.name)
                .blur(radius: shouldBlur ? 8 : 0)
        }
    }

    private func avatarPlaceholder(_ name: String) -> some View {
        ZStack {
            MatchaTokens.Colors.elevated
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(MatchaTokens.Colors.accent)
        }
    }

    // MARK: - Type Icon Pip

    private func typeIconPip(_ type: NotificationType) -> some View {
        Image(systemName: type.iconName)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(type.iconColor)
            .frame(width: 18, height: 18)
            .background(MatchaTokens.Colors.background, in: Circle())
            .overlay {
                Circle().strokeBorder(MatchaTokens.Colors.outline, lineWidth: 0.5)
            }
    }

    // MARK: - Notification Text

    private func notificationText(_ item: NotificationItem) -> some View {
        Group {
            switch item.type {
            case .matchCreated:
                (Text(item.name).fontWeight(.semibold) + Text(" matched with you!"))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)

            case .likeReceived:
                if shouldBlurLikes {
                    (Text("Someone").fontWeight(.semibold) + Text(" liked your profile"))
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                } else {
                    (Text(item.name).fontWeight(.semibold) + Text(" liked your profile"))
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                }

            case .dealConfirmed:
                (Text("Deal confirmed with ").font(.subheadline) + Text(item.name).fontWeight(.semibold))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)

            case .dealCheckedIn:
                (Text("Check-in completed with ").font(.subheadline) + Text(item.name).fontWeight(.semibold))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)

            case .dealReviewed:
                (Text("Deal reviewed with ").font(.subheadline) + Text(item.name).fontWeight(.semibold))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)

            case .dealCancelled:
                (Text("Deal cancelled with ").font(.subheadline) + Text(item.name).fontWeight(.semibold))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)

            case .dealNoShow:
                (Text("No-show reported for deal with ").font(.subheadline) + Text(item.name).fontWeight(.semibold))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.warning)

            case .offerApplication:
                (Text(item.name).fontWeight(.semibold) + Text(" applied to your offer"))
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }
        }
        .lineLimit(2)
    }

    // MARK: - Tap Handler

    private func handleTap(_ item: NotificationItem) {
        switch item.type {
        case .likeReceived:
            if shouldBlurLikes {
                showLikesPaywall = true
            } else if let profile = item.sourceProfile {
                selectedProfile = profile
            }
        case .matchCreated, .offerApplication:
            if let profile = item.sourceProfile {
                selectedProfile = profile
            }
        case .dealConfirmed, .dealCheckedIn, .dealReviewed, .dealCancelled, .dealNoShow:
            // Deal notifications -- profile tap for now
            if let profile = item.sourceProfile {
                selectedProfile = profile
            }
        }
    }

    // MARK: - Error Banner

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

    // MARK: - Skeleton

    private var notificationsSkeleton: some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 100, height: 10)
                    }

                    Spacer()
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.vertical, 14)
            }
        }
        .redacted(reason: .placeholder)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.25))
            Text("No notifications yet")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
            Text("Likes, matches, deal updates, and offer responses will appear here.")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MatchaTokens.Spacing.large)
    }
}

// MARK: - NotificationType

enum NotificationType {
    case matchCreated
    case likeReceived
    case dealConfirmed
    case dealCheckedIn
    case dealReviewed
    case dealCancelled
    case dealNoShow
    case offerApplication

    var iconName: String {
        switch self {
        case .matchCreated:     return "heart.fill"
        case .likeReceived:     return "heart.fill"
        case .dealConfirmed:    return "checkmark.circle.fill"
        case .dealCheckedIn:    return "mappin.circle.fill"
        case .dealReviewed:     return "star.fill"
        case .dealCancelled:    return "xmark.circle.fill"
        case .dealNoShow:       return "exclamationmark.triangle.fill"
        case .offerApplication: return "paperplane.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .matchCreated:     return MatchaTokens.Colors.accent
        case .likeReceived:     return Color(hex: 0xFF6B8A)
        case .dealConfirmed:    return MatchaTokens.Colors.success
        case .dealCheckedIn:    return MatchaTokens.Colors.baliBlue
        case .dealReviewed:     return MatchaTokens.Colors.accent
        case .dealCancelled:    return MatchaTokens.Colors.danger
        case .dealNoShow:       return MatchaTokens.Colors.warning
        case .offerApplication: return MatchaTokens.Colors.baliBlue
        }
    }
}

// MARK: - NotificationItem

struct NotificationItem: Identifiable {
    let id: String
    let type: NotificationType
    let name: String
    let avatarURL: URL?
    let timestamp: String
    let isRead: Bool
    let sourceProfile: UserProfile?
}

// MARK: - NotificationsStore

@MainActor
@Observable
final class NotificationsStore {
    private let repository: any MatchaRepository

    var items: [NotificationItem] = []
    var error: NetworkError?
    var hasLoaded = false
    var isLoading = false

    var unreadCount: Int {
        items.filter { !$0.isRead }.count
    }

    init(repository: any MatchaRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        error = nil
        isLoading = true
        defer { isLoading = false; hasLoaded = true }

        do {
            let summary = try await repository.fetchActivitySummary()
            items = buildNotifications(from: summary)
        } catch let networkError as NetworkError {
            self.error = networkError
            items = []
        } catch {
            self.error = .networkError(error)
            items = []
        }
    }

    // MARK: - Build Notifications from ActivitySummary

    private func buildNotifications(from summary: ActivitySummary) -> [NotificationItem] {
        var result: [NotificationItem] = []

        // Likes received
        for (index, profile) in summary.likes.enumerated() {
            result.append(NotificationItem(
                id: "like-\(profile.id.uuidString)",
                type: .likeReceived,
                name: profile.name,
                avatarURL: profile.photoURL,
                timestamp: relativeTime(minutesAgo: index * 47 + 12),
                isRead: index > 2,
                sourceProfile: profile
            ))
        }

        // Active deals -- treated as confirmations
        for (index, deal) in summary.activeDeals.enumerated() {
            result.append(NotificationItem(
                id: "deal-active-\(deal.id.uuidString)",
                type: deal.status == .confirmed ? .dealConfirmed : .dealCheckedIn,
                name: deal.partnerName,
                avatarURL: nil,
                timestamp: relativeTime(minutesAgo: index * 120 + 30),
                isRead: false,
                sourceProfile: nil
            ))
        }

        // Finished deals
        for (index, deal) in summary.finishedDeals.enumerated() {
            result.append(NotificationItem(
                id: "deal-finished-\(deal.id.uuidString)",
                type: .dealReviewed,
                name: deal.partnerName,
                avatarURL: nil,
                timestamp: relativeTime(minutesAgo: index * 600 + 1440),
                isRead: true,
                sourceProfile: nil
            ))
        }

        // Cancelled deals
        for (index, deal) in summary.cancelledDeals.enumerated() {
            result.append(NotificationItem(
                id: "deal-cancelled-\(deal.id.uuidString)",
                type: .dealCancelled,
                name: deal.partnerName,
                avatarURL: nil,
                timestamp: relativeTime(minutesAgo: index * 300 + 720),
                isRead: true,
                sourceProfile: nil
            ))
        }

        // No-show deals
        for (index, deal) in summary.noShowDeals.enumerated() {
            result.append(NotificationItem(
                id: "deal-noshow-\(deal.id.uuidString)",
                type: .dealNoShow,
                name: deal.partnerName,
                avatarURL: nil,
                timestamp: relativeTime(minutesAgo: index * 400 + 600),
                isRead: true,
                sourceProfile: nil
            ))
        }

        // Offer applications
        for (index, application) in summary.applications.enumerated() {
            result.append(NotificationItem(
                id: "app-\(application.id.uuidString)",
                type: .offerApplication,
                name: application.applicant.name,
                avatarURL: application.applicant.photoURL,
                timestamp: application.submittedAt,
                isRead: !application.isActionRequired,
                sourceProfile: application.applicant
            ))
        }

        // Sort by unread first, then by position (newest first implicitly by construction)
        return result.sorted { lhs, rhs in
            if lhs.isRead != rhs.isRead { return !lhs.isRead }
            return false
        }
    }

    private func relativeTime(minutesAgo: Int) -> String {
        if minutesAgo < 60 { return "\(minutesAgo)m ago" }
        let hours = minutesAgo / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days == 1 { return "Yesterday" }
        if days < 7 { return "\(days)d ago" }
        let weeks = days / 7
        return "\(weeks)w ago"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationsView(
            currentUser: MockSeedData.makeCurrentUser(role: .blogger, name: "Nadia"),
            repository: MockMatchaRepository()
        )
    }
    .preferredColorScheme(.dark)
}
