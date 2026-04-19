import Observation
import SwiftUI

struct ProfileView: View {
    @State private var store: ProfileStore
    @State private var activeSheet: ActiveSheet?
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showPaywall = false
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
                statsGridRow
                actionRow

                aboutSection

                nichesSection

                personalInfoSection

                socialAccountsSection

                portfolioSection

                planSection

                devToolsSection

                signOutButton
            }
            .padding(.bottom, 100)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
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
        .sheet(isPresented: $showPaywall) {
            PaywallView(.general)
        }
        .navigationDestination(isPresented: $showNotifications) {
            NotificationsView(
                currentUser: store.currentUser,
                repository: repository
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
    private var heroHeight: CGFloat { hasPhoto ? 340 : 240 }

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
                    MatchaTokens.Colors.background
                }
            }
            .frame(height: 340)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.45),
                    .init(color: MatchaTokens.Colors.background.opacity(0.5), location: 0.72),
                    .init(color: MatchaTokens.Colors.background, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 340)

            topBar

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                nameBlock
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(height: 340)
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

            HStack(spacing: 10) {
                Button { showNotifications = true } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.4), in: Circle())
                }

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.4), in: Circle())
                }
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
        // Иерархия бейджей:
        // - .verified (паспорт+selfie) → VERIFIED (bali blue)
        // - .blueCheck (3+ deals + content proof) → VERIFIED + APPROVED (обе видны)
        // - .shadow → ничего
        HStack(spacing: 8) {
            if store.currentUser.verificationLevel == .verified
                || store.currentUser.verificationLevel == .blueCheck {
                verifiedPill
            }
            if store.currentUser.verificationLevel == .blueCheck {
                approvedPill
            }
        }
    }

    private var verifiedPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 10, weight: .bold))
            Text("VERIFIED")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
        }
        .foregroundStyle(MatchaTokens.Colors.baliBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(MatchaTokens.Colors.baliBlue.opacity(0.18), in: Capsule())
        .overlay(Capsule().strokeBorder(MatchaTokens.Colors.baliBlue.opacity(0.35), lineWidth: 0.5))
    }

    private var approvedPill: some View {
        HStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 10, weight: .bold))
            Text("APPROVED")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.6)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(MatchaTokens.Colors.accent, in: Capsule())
    }

    // MARK: - Stats Grid Row (4 cards: Rating / Collabs / Visits / Badges)

    private var statsGridRow: some View {
        HStack(spacing: 10) {
            statCard(
                label: "Rating",
                value: store.currentUser.rating.map { String(format: "%.1f", $0) } ?? "—",
                icon: "star.fill",
                iconColor: MatchaTokens.Colors.warning
            )
            statCard(
                label: "Collabs",
                value: "\(store.currentUser.completedCollabsCount)",
                icon: nil,
                iconColor: .clear
            )
            statCard(
                label: "Visits",
                value: "\(store.currentUser.verifiedVisits)",
                icon: nil,
                iconColor: .clear
            )
            statCard(
                label: "Badges",
                value: "\(store.currentUser.badges.count)",
                icon: nil,
                iconColor: .clear
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func statCard(label: String, value: String, icon: String?, iconColor: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(iconColor)
                }
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - Action Row (Edit Profile + Go Pro)

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { activeSheet = .editProfile } label: {
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
            }

            Button { showPaywall = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("Go Pro")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [MatchaTokens.Colors.accent, Color(hex: 0x9BE62E)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 4)
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

    // MARK: - Personal Info

    @ViewBuilder
    private var personalInfoSection: some View {
        let user = store.currentUser
        let rows: [(String, String)] = [
            ("Nationality", user.nationality ?? ""),
            ("Residence", user.residence ?? ""),
            ("Gender", user.gender ?? ""),
            ("Birthday", formatBirthday(user.birthday)),
            ("Languages", formatLanguages(user.languages)),
        ].filter { !$0.1.isEmpty }

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Info")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    ForEach(rows, id: \.0) { label, value in
                        HStack {
                            Text(label)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.55))
                            Spacer()
                            Text(value)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        } else {
            Button { activeSheet = .editProfile } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add personal info")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(MatchaTokens.Colors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
        }
    }

    private func formatLanguages(_ langs: [String]) -> String {
        guard !langs.isEmpty else { return "" }
        let flags: [String: String] = [
            "russian": "🇷🇺", "english": "🇬🇧", "indonesian": "🇮🇩", "mandarin": "🇨🇳",
            "japanese": "🇯🇵", "korean": "🇰🇷", "french": "🇫🇷", "german": "🇩🇪",
            "spanish": "🇪🇸", "italian": "🇮🇹", "portuguese": "🇵🇹", "dutch": "🇳🇱",
            "arabic": "🇸🇦", "hindi": "🇮🇳", "turkish": "🇹🇷", "thai": "🇹🇭",
            "vietnamese": "🇻🇳", "polish": "🇵🇱", "ukrainian": "🇺🇦", "hebrew": "🇮🇱",
            "en": "🇬🇧", "ru": "🇷🇺", "id": "🇮🇩", "zh": "🇨🇳", "ja": "🇯🇵", "ko": "🇰🇷",
            "fr": "🇫🇷", "de": "🇩🇪", "es": "🇪🇸", "it": "🇮🇹",
        ]
        return langs.map { lang in
            let key = lang.lowercased()
            let flag = flags[key] ?? ""
            let display = lang.count <= 2 ? lang.uppercased() : lang.capitalized
            return flag.isEmpty ? display : "\(flag) \(display)"
        }.joined(separator: "  ")
    }

    private func formatBirthday(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
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
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(MatchaTokens.Colors.accent.opacity(0.12), in: Capsule())
                            .overlay(Capsule().strokeBorder(MatchaTokens.Colors.accent.opacity(0.25), lineWidth: 1))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    // MARK: - Social Accounts (per design: simple rows с colored square icon)

    @ViewBuilder
    private var socialAccountsSection: some View {
        if store.currentUser.hasSocialAccounts {
            VStack(alignment: .leading, spacing: 10) {
                Text("Social")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)

                VStack(spacing: 0) {
                    if let handle = store.currentUser.instagramHandle {
                        socialRow(
                            name: "Instagram",
                            handle: "@\(handle)",
                            followers: store.currentUser.instagramFollowers ?? store.currentUser.followersCount,
                            color: Color(hex: 0xE1306C),
                            showDivider: store.currentUser.tiktokHandle != nil
                        )
                    }
                    if let handle = store.currentUser.tiktokHandle {
                        socialRow(
                            name: "TikTok",
                            handle: "@\(handle)",
                            followers: store.currentUser.tiktokFollowers,
                            color: .white,
                            showDivider: false
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
    }

    private func socialRow(name: String, handle: String, followers: Int?, color: Color, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Colored square icon с буквой (I / T)
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    Text(String(name.prefix(1)))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 4) {
                        Text(handle)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        if let f = followers, f > 0 {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.3))
                            Text(formatCount(f))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.vertical, 10)

            if showDivider {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 48)
            }
        }
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

    // MARK: - Portfolio (per design: 3-col grid градиентных плиток)

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portfolio")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button { activeSheet = .editProfile } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }

            // Реальные загруженные фото + добор плейсхолдерами до 6 плиток.
            let uploaded = store.currentUser.photoURLs
            let placeholderCount = max(0, 6 - uploaded.count)
            let placeholderHues: [Double] = [20, 80, 160, 200, 260, 300]
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                spacing: 6
            ) {
                ForEach(Array(uploaded.enumerated()), id: \.offset) { _, url in
                    portfolioPhotoTile(url: url)
                }
                ForEach(0..<placeholderCount, id: \.self) { idx in
                    portfolioTile(hue: placeholderHues[(uploaded.count + idx) % placeholderHues.count])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    private func portfolioPhotoTile(url: URL) -> some View {
        // Реальная загруженная фотка в сетке Portfolio — 4:5 crop.
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure:
                Color(white: 0.08)
            default:
                ZStack {
                    Color(white: 0.08)
                    ProgressView().tint(MatchaTokens.Colors.accent.opacity(0.6)).scaleEffect(0.7)
                }
            }
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func portfolioTile(hue: Double) -> some View {
        // Cinematic градиентная плитка 4:5 с diagonal stripe overlay — как в дизайне.
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: hue / 360, saturation: 0.55, brightness: 0.28),
                    Color(hue: (hue + 30) / 360, saturation: 0.45, brightness: 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Diagonal stripe pattern (repeating)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.clear, Color.white.opacity(0.04), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .aspectRatio(4.0 / 5.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    // MARK: - Dev Tools

    @State private var devToolsMessage: String?

    // MARK: - Plan Section

    private var planSection: some View {
        VStack(spacing: 14) {
            // Upgrade banner (hidden if already on top tier)
            if store.currentUser.subscriptionPlan != .black {
                Button { showPaywall = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                        Text("Upgrade your plan")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.black, Color(hex: 0x1a1a1a)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.accent.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // Your plan row
            Button { showPaywall = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(planTint.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: planIcon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(planTint)
                    }

                    Text("Your plan")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(store.currentUser.subscriptionPlan.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(planTint)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var planTint: Color {
        switch store.currentUser.subscriptionPlan {
        case .free:  return MatchaTokens.Colors.textSecondary
        case .pro:   return MatchaTokens.Colors.accent
        case .black: return Color(hex: 0xD4B45C)
        }
    }

    private var planIcon: String {
        switch store.currentUser.subscriptionPlan {
        case .free:  return "person.fill"
        case .pro:   return "sparkles"
        case .black: return "crown.fill"
        }
    }

    private var devToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEV TOOLS")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MatchaTokens.Colors.warning)
                .tracking(1)
                .padding(.horizontal, 24)

            Button {
                Task {
                    guard let userId = NetworkService.shared.currentUserID else { return }
                    do {
                        let _: [String: String] = try await NetworkService.shared.request(
                            .POST, path: "/admin/reset-swipes/\(userId)"
                        )
                        devToolsMessage = "Swipes reset! Pull to refresh feed"
                    } catch {
                        devToolsMessage = "Failed: \(error.localizedDescription)"
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0x5B7AFF), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Swipes")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                        Text("See all profiles again in feed")
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)

            if let msg = devToolsMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(role: .destructive) {
            onSignOut?()
        } label: {
            Text("Sign out")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MatchaTokens.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.danger.opacity(0.35), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
        return "Influencer"
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
            ? "Add a description so influencers know what your business offers."
            : "Write about yourself so brands know what you do."
    }

    let settingsRows = [
        SettingsRow(icon: "creditcard.fill", title: "Subscription"),
        SettingsRow(icon: "person.circle", title: "Account"),
        SettingsRow(icon: "bell.badge", title: "Notifications"),
        SettingsRow(icon: "lock.shield", title: "Privacy"),
        SettingsRow(icon: "questionmark.circle", title: "Support"),
    ]

    init(currentUser: UserProfile) {
        self.currentUser = currentUser
    }
}

// MARK: - Social Accounts Section

/// Self-contained social accounts card with platform tabs and stat cards.
private struct SocialAccountsSectionContent: View {
    let user: UserProfile
    @State private var selectedPlatform: Platform = .instagram

    // MARK: Platform enum local to this component

    enum Platform: String, CaseIterable, Identifiable {
        case instagram = "Instagram"
        case youtube   = "YouTube"
        case tiktok    = "TikTok"
        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .instagram: return "camera.circle.fill"
            case .youtube:   return "play.rectangle.fill"
            case .tiktok:    return "music.note.list"
            }
        }

        var accentColor: Color {
            switch self {
            case .instagram: return Color(hex: 0xE1306C)
            case .youtube:   return Color(hex: 0xFF0000)
            case .tiktok:    return Color(hex: 0x69C9D0)
            }
        }
    }

    // MARK: Available platforms (only those with a handle)

    private var availablePlatforms: [Platform] {
        var platforms: [Platform] = []
        if user.instagramHandle != nil { platforms.append(.instagram) }
        if user.youtubeHandle != nil   { platforms.append(.youtube) }
        if user.tiktokHandle != nil    { platforms.append(.tiktok) }
        return platforms
    }

    private var activePlatform: Platform {
        if availablePlatforms.contains(selectedPlatform) {
            return selectedPlatform
        }
        return availablePlatforms.first ?? .instagram
    }

    // MARK: Stats for selected platform

    private var followersValue: Int? {
        switch activePlatform {
        case .instagram: return user.instagramFollowers ?? user.followersCount
        case .youtube:   return user.youtubeSubscribers
        case .tiktok:    return user.tiktokFollowers
        }
    }

    private var engagementValue: Double? {
        switch activePlatform {
        case .instagram: return user.instagramEngagement
        case .youtube:   return nil
        case .tiktok:    return nil
        }
    }

    private var handleText: String {
        switch activePlatform {
        case .instagram: return user.instagramHandle.map { "@\($0)" } ?? ""
        case .youtube:   return user.youtubeHandle ?? ""
        case .tiktok:    return user.tiktokHandle.map { "@\($0)" } ?? ""
        }
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Social Accounts")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)

            // Platform tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availablePlatforms) { platform in
                        platformTab(platform)
                    }
                }
            }

            // Stat cards row
            HStack(spacing: 10) {
                statCard(
                    title: activePlatform == .youtube ? "Subscribers" : "Followers",
                    value: followersValue.map { formatCompact($0) } ?? "—"
                )
                statCard(
                    title: "Avg. Views",
                    value: "—"
                )
                statCard(
                    title: "Engagement",
                    value: engagementValue.map { String(format: "%.1f%%", $0) } ?? "—"
                )
            }
        }
    }

    // MARK: - Platform Tab

    private func platformTab(_ platform: Platform) -> some View {
        Button {
            withAnimation(MatchaTokens.Animations.tabSwitch) {
                selectedPlatform = platform
            }
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: platform.iconName)
                        .font(.system(size: 14, weight: .semibold))
                    Text(handleForPlatform(platform))
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(activePlatform == platform ? .white : .white.opacity(0.45))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)

                // Accent underline for active tab
                Rectangle()
                    .fill(activePlatform == platform ? platform.accentColor : Color.clear)
                    .frame(height: 2)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private func handleForPlatform(_ platform: Platform) -> String {
        switch platform {
        case .instagram: return user.instagramHandle.map { "@\($0)" } ?? "Instagram"
        case .youtube:   return user.youtubeHandle ?? "YouTube"
        case .tiktok:    return user.tiktokHandle.map { "@\($0)" } ?? "TikTok"
        }
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MatchaTokens.Colors.elevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                }
        )
    }

    // MARK: - Formatting

    private func formatCompact(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000     { return String(format: "%.0fK", Double(count) / 1_000) }
        return "\(count)"
    }
}
