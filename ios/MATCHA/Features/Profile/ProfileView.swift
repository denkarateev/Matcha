import Observation
import SwiftUI

struct ProfileView: View {
    @State private var store: ProfileStore
    @State private var activeSheet: ActiveSheet?
    @State private var showSettings = false
    private let repository: any MatchaRepository

    var onProfileSaved: ((UserProfile) -> Void)?
    var onSignOut: (() -> Void)?

    init(
        currentUser: UserProfile,
        repository: any MatchaRepository,
        onProfileSaved: ((UserProfile) -> Void)? = nil,
        onSignOut: (() -> Void)? = nil
    ) {
        _store = State(initialValue: ProfileStore(currentUser: currentUser))
        self.repository = repository
        self.onProfileSaved = onProfileSaved
        self.onSignOut = onSignOut
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                actionRow
                sectionDivider

                aboutSection
                sectionDivider

                nichesSection
                sectionDivider

                statsSection
                sectionDivider

                portfolioSection
                sectionDivider

                settingsRow
                sectionDivider

                signOutButton
            }
            .padding(.bottom, 100)
        }
        .background(Color(hex: 0x0A0A0A).ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editProfile:
                EditProfileView(profile: store.currentUser, repository: repository) { updated in
                    store.currentUser = updated
                    onProfileSaved?(updated)
                }
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            ProfileSettingsListView(
                settingsRows: store.settingsRows,
                onSignOut: onSignOut
            )
        }
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    // MARK: - Hero

    private var hasPhoto: Bool { store.primaryPhotoURL != nil }
    private var heroHeight: CGFloat { hasPhoto ? 460 : 240 }

    private var heroSection: some View {
        VStack(spacing: 0) {
            if hasPhoto {
                photoHero
            } else {
                noPhotoHero
            }
        }
    }

    // MARK: Hero with photo

    private var photoHero: some View {
        ZStack(alignment: .top) {
            AsyncImage(url: store.primaryPhotoURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color(hex: 0x0A0A0A)
                }
            }
            .frame(height: 460)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.45),
                    .init(color: Color(hex: 0x0A0A0A).opacity(0.5), location: 0.72),
                    .init(color: Color(hex: 0x0A0A0A), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 460)

            topBar

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                nameBlock
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(height: 460)
        }
        .frame(height: 460)
    }

    // MARK: Hero without photo — compact

    private var noPhotoHero: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .semibold))
                    Text(store.districtLabel)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08), in: Capsule())

                Spacer()

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)

            // Avatar circle + name
            VStack(spacing: 16) {
                Button { activeSheet = .editProfile } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Circle().strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            }

                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                            Text("Add Photo")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }

                nameBlock
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // MARK: Shared

    private var topBar: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 11, weight: .semibold))
                Text(store.districtLabel)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.4), in: Capsule())

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.4), in: Circle())
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
    }

    private var nameBlock: some View {
        VStack(alignment: hasPhoto ? .leading : .center, spacing: 6) {
            HStack(spacing: 8) {
                Text(store.currentUser.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                verificationIcon
            }

            HStack(spacing: 6) {
                Text(store.rolePillLabel)
                Text("·").foregroundStyle(.white.opacity(0.4))
                Text(store.collaborationChip)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                if let followers = store.currentUser.followersCount, followers > 0 {
                    Text("✓ \(formatCount(followers))")
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
                if store.currentUser.completedCollabsCount > 0 {
                    Text("\(store.currentUser.completedCollabsCount) collabs")
                        .foregroundStyle(.white.opacity(0.5))
                }
                if let rating = store.currentUser.rating, rating > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 11))
                        Text(String(format: "%.1f", rating))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                } else {
                    MatchaBadge(type: .new, size: .small)
                }
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.top, 2)

            verificationStatusPill
                .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var verificationIcon: some View {
        switch store.currentUser.verificationLevel {
        case .blueCheck:
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(MatchaTokens.Colors.baliBlue)
        case .verified:
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MatchaTokens.Colors.accent)
        case .shadow:
            EmptyView()
        }
    }

    @ViewBuilder
    private var verificationStatusPill: some View {
        switch store.currentUser.verificationLevel {
        case .blueCheck:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Blue Check")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(MatchaTokens.Colors.baliBlue, in: Capsule())
        case .verified:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 11, weight: .bold))
                Text("Approved by MATCHA")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(MatchaTokens.Colors.accent, in: Capsule())
        case .shadow:
            EmptyView()
        }
    }

    // MARK: - Action Row

    private var actionRow: some View {
        Button { activeSheet = .editProfile } label: {
            HStack(spacing: 6) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .semibold))
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)

            Text(store.bioOrFallback)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Niches

    private var nichesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Niches")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)

            if store.currentUser.niches.isEmpty {
                Button { activeSheet = .editProfile } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Add your niches")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(MatchaTokens.Colors.accent)
                }
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(store.currentUser.niches, id: \.self) { niche in
                        Text(niche)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.08), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(value: store.currentUser.completedCollabsCount, label: "Collabs")
            statDivider
            statItem(
                value: store.currentUser.verifiedVisits,
                label: "Visits"
            )
            statDivider
            statItem(
                value: store.currentUser.badges.count,
                label: "Badges"
            )
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 36)
    }

    // MARK: - Portfolio

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portfolio Wall")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            // Empty state
            Button { activeSheet = .editProfile } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 48, height: 48)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Showcase your best work")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Add past collabs to get 3x more matches")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .padding(14)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Settings

    private var settingsRow: some View {
        NavigationLink {
            ProfileSettingsListView(
                settingsRows: store.settingsRows,
                onSignOut: onSignOut
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.4))
                Text("Settings")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(role: .destructive) {
            onSignOut?()
        } label: {
            Text("Sign Out")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.red.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

// MARK: - Supporting Types

private enum ActiveSheet: String, Identifiable {
    case editProfile
    var id: String { rawValue }
}

struct VerificationStep: Hashable {
    let title: String
    let done: Bool
    let unlock: String?
}

struct SettingsRow: Hashable {
    let icon: String
    let title: String
}

// MARK: - ProfileStore

@MainActor
@Observable
final class ProfileStore {
    var currentUser: UserProfile

    var primaryPhotoURL: URL? {
        currentUser.photoURL ?? currentUser.photoURLs.first
    }

    var districtLabel: String {
        currentUser.district ?? currentUser.locationDistrict ?? "Bali"
    }

    var rolePillLabel: String {
        if currentUser.role == .business {
            return currentUser.category?.title ?? "Business"
        }
        return "Creator"
    }

    var collaborationChip: String {
        switch currentUser.collaborationType {
        case .paid: "Paid"
        case .barter: "Barter"
        case .both: "Paid + Barter"
        }
    }

    var bioOrFallback: String {
        let trimmed = currentUser.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return currentUser.role == .business
            ? "Add a description so creators know what your business offers."
            : "Write about yourself so brands know what you do."
    }

    let settingsRows = [
        SettingsRow(icon: "creditcard.fill", title: "Subscription"),
        SettingsRow(icon: "chart.bar.doc.horizontal.fill", title: "Deals CRM"),
        SettingsRow(icon: "person.circle", title: "Account"),
        SettingsRow(icon: "bell.badge", title: "Notifications"),
        SettingsRow(icon: "lock.shield", title: "Privacy"),
        SettingsRow(icon: "questionmark.circle", title: "Support"),
    ]

    init(currentUser: UserProfile) {
        self.currentUser = currentUser
    }
}
