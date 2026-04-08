import SwiftUI

// MARK: - SettingsDetailView (Router)

/// Routes from a SettingsRow to the correct sub-view.
struct SettingsDetailView: View {
    let row: SettingsRow

    var body: some View {
        Group {
            switch row.title {
            case "Account":       AccountSettingsView()
            case "Deals CRM":     DealsCRMView()
            case "Notifications": NotificationSettingsView()
            case "Privacy":       PrivacySettingsView()
            case "Support":       SupportView()
            default:
                VStack(spacing: 16) {
                    Image(systemName: row.icon)
                        .font(.largeTitle)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    Text(row.title)
                        .font(MatchaTokens.Typography.title2)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    Text("Coming soon")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MatchaTokens.Colors.background.ignoresSafeArea())
            }
        }
    }
}

// MARK: - AccountSettingsView

struct AccountSettingsView: View {
    var onSignOut: (() -> Void)?

    @State private var email = "user@example.com"
    @State private var phone = "+62 812 3456 7890"
    @State private var showChangePassword = false
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    // Language picker
    @AppStorage("app_language") private var selectedLanguage: AppLanguage = .english

    // Delete account flow
    @State private var deleteStep: DeleteAccountStep = .none
    @State private var deleteConfirmText = ""
    @State private var hasActiveDeals = false // TODO: wire to real data
    @State private var showDeleteSuccess = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Email & Phone
                settingsCard {
                    settingsFieldRow(
                        icon: "envelope.fill",
                        iconColor: Color(hex: 0x7EB2FF),
                        label: "Email",
                        value: $email
                    )

                    cardDivider

                    settingsFieldRow(
                        icon: "phone.fill",
                        iconColor: MatchaTokens.Colors.success,
                        label: "Phone Number",
                        value: $phone
                    )
                }

                // Language
                settingsCard {
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: 0xC084FC).opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "globe")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0xC084FC))
                            }

                            Text("Language")
                                .font(.subheadline)
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)

                            Spacer()

                            Picker("", selection: $selectedLanguage) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.displayName).tag(language)
                                }
                            }
                            .tint(MatchaTokens.Colors.accent)
                            .labelsHidden()
                        }
                        .padding(.horizontal, MatchaTokens.Spacing.medium)
                        .padding(.vertical, 14)
                    }
                }

                // Change Password
                settingsCard {
                    Button(action: { withAnimation { showChangePassword.toggle() } }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(MatchaTokens.Colors.warning.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "lock.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MatchaTokens.Colors.warning)
                            }

                            Text("Change Password")
                                .font(.subheadline)
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)

                            Spacer()

                            Image(systemName: showChangePassword ? "chevron.up" : "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
                        }
                        .padding(.horizontal, MatchaTokens.Spacing.medium)
                        .padding(.vertical, 14)
                    }

                    if showChangePassword {
                        cardDivider

                        VStack(spacing: 12) {
                            secureField("Current Password", text: $currentPassword)
                            secureField("New Password", text: $newPassword)
                            secureField("Confirm New Password", text: $confirmPassword)

                            Button(action: {}) {
                                Text("Update Password")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(MatchaTokens.Colors.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.horizontal, MatchaTokens.Spacing.medium)
                        .padding(.bottom, 14)
                    }
                }

                // Delete Account (spec 15.1)
                settingsCard {
                    Button(action: { startDeleteFlow() }) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(MatchaTokens.Colors.danger.opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "person.badge.minus")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MatchaTokens.Colors.danger)
                            }

                            Text("Delete Account")
                                .font(.subheadline)
                                .foregroundStyle(MatchaTokens.Colors.danger)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(MatchaTokens.Colors.danger.opacity(0.4))
                        }
                        .padding(.horizontal, MatchaTokens.Spacing.medium)
                        .padding(.vertical, 14)
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.large)
            .padding(.bottom, 32)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        // Step 1: Active deals warning
        .alert(
            "Active Deals Found",
            isPresented: Binding(
                get: { deleteStep == .activeDealsWarning },
                set: { if !$0 { deleteStep = .none } }
            )
        ) {
            Button("Cancel", role: .cancel) { deleteStep = .none }
            Button("Continue Anyway", role: .destructive) {
                deleteStep = .confirmDialog
            }
        } message: {
            Text("You have active deals. Deleting your account will cancel them.")
        }
        // Step 2: First confirmation
        .alert(
            "Delete Account?",
            isPresented: Binding(
                get: { deleteStep == .confirmDialog },
                set: { if !$0 { deleteStep = .none } }
            )
        ) {
            Button("Cancel", role: .cancel) { deleteStep = .none }
            Button("Delete", role: .destructive) {
                deleteStep = .typeConfirm
            }
        } message: {
            Text("Are you sure? This cannot be undone.")
        }
        // Step 3: Type DELETE to confirm
        .alert(
            "Type DELETE to Confirm",
            isPresented: Binding(
                get: { deleteStep == .typeConfirm },
                set: { if !$0 { deleteStep = .none } }
            )
        ) {
            TextField("Type DELETE", text: $deleteConfirmText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
                deleteStep = .none
            }
            Button("Confirm Delete", role: .destructive) {
                if deleteConfirmText.trimmingCharacters(in: .whitespaces).uppercased() == "DELETE" {
                    deleteStep = .gracePeriodInfo
                }
                deleteConfirmText = ""
            }
        } message: {
            Text("This will permanently delete your account and all data.")
        }
        // Step 4: Grace period info
        .alert(
            "30-Day Grace Period",
            isPresented: Binding(
                get: { deleteStep == .gracePeriodInfo },
                set: { if !$0 { deleteStep = .none } }
            )
        ) {
            Button("Cancel", role: .cancel) { deleteStep = .none }
            Button("Delete My Account", role: .destructive) {
                executeDeleteAccount()
            }
        } message: {
            Text("Your account will be hidden immediately. You have 30 days to restore it by logging in again.")
        }
        // Success message
        .alert(
            "Account Deleted",
            isPresented: $showDeleteSuccess
        ) {
            Button("OK") {
                NetworkService.shared.logout(notifySessionInvalidated: true)
            }
        } message: {
            Text("Your account has been scheduled for deletion. You can restore it within 30 days by logging in.")
        }
        // Delete error
        .alert(
            "Delete Failed",
            isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )
        ) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "Something went wrong. Please try again.")
        }
        // Loading overlay
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Deleting account...")
                        .tint(.white)
                        .foregroundStyle(.white)
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .allowsHitTesting(!isDeleting)
    }

    // MARK: - Delete Account Flow

    private func startDeleteFlow() {
        if hasActiveDeals {
            deleteStep = .activeDealsWarning
        } else {
            deleteStep = .confirmDialog
        }
    }

    private func executeDeleteAccount() {
        deleteStep = .none
        isDeleting = true
        deleteError = nil

        Task {
            do {
                try await NetworkService.shared.requestVoid(.DELETE, path: "/auth/me")
                isDeleting = false
                showDeleteSuccess = true
            } catch {
                isDeleting = false
                deleteError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func settingsFieldRow(icon: String, iconColor: Color, label: String, value: Binding<String>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                TextField(label, text: value)
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }

    private func secureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.subheadline)
            .foregroundStyle(MatchaTokens.Colors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )
    }
}

// MARK: - NotificationSettingsView

struct NotificationSettingsView: View {
    @State private var matchesEnabled = true
    @State private var messagesEnabled = true
    @State private var dealsEnabled = true
    @State private var offersEnabled = false
    @State private var reminderEnabled = true
    @State private var weeklyDigestEnabled = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Activity
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Activity")

                    settingsCard {
                        notificationToggle(
                            icon: "heart.fill",
                            iconColor: MatchaTokens.Colors.danger,
                            title: "New Matches",
                            subtitle: "When someone likes your profile back",
                            isOn: $matchesEnabled
                        )

                        cardDivider

                        notificationToggle(
                            icon: "message.fill",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "Messages",
                            subtitle: "New messages from your connections",
                            isOn: $messagesEnabled
                        )

                        cardDivider

                        notificationToggle(
                            icon: "checkmark.circle.fill",
                            iconColor: MatchaTokens.Colors.accent,
                            title: "Deals",
                            subtitle: "Deal confirmations, check-ins & reviews",
                            isOn: $dealsEnabled
                        )
                    }
                }

                // Offers & Promotions
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Offers & Promotions")

                    settingsCard {
                        notificationToggle(
                            icon: "tag.fill",
                            iconColor: MatchaTokens.Colors.warning,
                            title: "New Offers",
                            subtitle: "Offers matching your niche and profile",
                            isOn: $offersEnabled
                        )

                        cardDivider

                        notificationToggle(
                            icon: "bolt.fill",
                            iconColor: MatchaTokens.Colors.warning,
                            title: "Last Minute Offers",
                            subtitle: "Time-sensitive opportunities nearby",
                            isOn: $offersEnabled
                        )
                    }
                }

                // Digest
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Summary")

                    settingsCard {
                        notificationToggle(
                            icon: "bell.badge.fill",
                            iconColor: MatchaTokens.Colors.textSecondary,
                            title: "Reminders",
                            subtitle: "Upcoming deal reminders",
                            isOn: $reminderEnabled
                        )

                        cardDivider

                        notificationToggle(
                            icon: "envelope.fill",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "Weekly Digest",
                            subtitle: "Summary of your activity each week",
                            isOn: $weeklyDigestEnabled
                        )
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.large)
            .padding(.bottom, 32)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func notificationToggle(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
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

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MatchaTokens.Colors.accent)
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }
}

// MARK: - PrivacySettingsView

struct PrivacySettingsView: View {
    @State private var showProfile = true
    @State private var showOnlineStatus = true
    @State private var allowMessagesFromAll = false
    @State private var showRatingPublicly = true
    @State private var shareActivityData = false
    @State private var blockedUsers: [String] = ["@luna_creator", "@bali_food_guide"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Visibility
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Visibility")

                    settingsCard {
                        privacyToggle(
                            icon: "eye.fill",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "Show My Profile",
                            subtitle: "Appear in match feed and searches",
                            isOn: $showProfile
                        )

                        cardDivider

                        privacyToggle(
                            icon: "circle.fill",
                            iconColor: MatchaTokens.Colors.success,
                            title: "Show Online Status",
                            subtitle: "Let others see when you're active",
                            isOn: $showOnlineStatus
                        )

                        cardDivider

                        privacyToggle(
                            icon: "star.fill",
                            iconColor: MatchaTokens.Colors.warning,
                            title: "Public Rating",
                            subtitle: "Show your rating score on your profile",
                            isOn: $showRatingPublicly
                        )
                    }
                }

                // Messaging
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Messaging")

                    settingsCard {
                        privacyToggle(
                            icon: "message.fill",
                            iconColor: MatchaTokens.Colors.accent,
                            title: "Messages from Anyone",
                            subtitle: "Allow non-matches to message you",
                            isOn: $allowMessagesFromAll
                        )

                        cardDivider

                        privacyToggle(
                            icon: "chart.bar.fill",
                            iconColor: MatchaTokens.Colors.textSecondary,
                            title: "Share Activity Data",
                            subtitle: "Help improve recommendations",
                            isOn: $shareActivityData
                        )

                        cardDivider

                        privacyToggle(
                            icon: "globe",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "Auto-translate Messages",
                            subtitle: "Show translation prompts for foreign-language messages",
                            isOn: Binding(
                                get: { TranslationService.shared.autoTranslateEnabled },
                                set: { TranslationService.shared.autoTranslateEnabled = $0 }
                            )
                        )
                    }
                }

                // Block List
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Blocked Users (\(blockedUsers.count))")

                    if blockedUsers.isEmpty {
                        emptyBlockList
                    } else {
                        settingsCard {
                            ForEach(Array(blockedUsers.enumerated()), id: \.element) { idx, handle in
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(MatchaTokens.Colors.elevated)
                                            .frame(width: 34, height: 34)
                                        Text(String(handle.dropFirst().prefix(1)).uppercased())
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                                    }

                                    Text(handle)
                                        .font(.subheadline)
                                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                                    Spacer()

                                    Button("Unblock") {
                                        withAnimation { _ = blockedUsers.remove(at: idx) }
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(MatchaTokens.Colors.danger)
                                }
                                .padding(.horizontal, MatchaTokens.Spacing.medium)
                                .padding(.vertical, 12)

                                if idx < blockedUsers.count - 1 {
                                    cardDivider
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.large)
            .padding(.bottom, 32)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var emptyBlockList: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.body)
                .foregroundStyle(MatchaTokens.Colors.success)
            Text("No blocked users")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .padding(MatchaTokens.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
    }

    private func privacyToggle(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
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

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(MatchaTokens.Colors.accent)
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }
}

// MARK: - SupportView

struct SupportView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Help
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Help")

                    settingsCard {
                        supportRow(
                            icon: "questionmark.circle.fill",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "FAQ",
                            subtitle: "Frequently asked questions",
                            action: {}
                        )

                        cardDivider

                        supportRow(
                            icon: "book.closed.fill",
                            iconColor: MatchaTokens.Colors.accent,
                            title: "How It Works",
                            subtitle: "Guides for creators and businesses",
                            action: {}
                        )

                        cardDivider

                        supportRow(
                            icon: "video.fill",
                            iconColor: MatchaTokens.Colors.warning,
                            title: "Video Tutorials",
                            subtitle: "Get the most out of MATCHA",
                            action: {}
                        )
                    }
                }

                // Contact
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Contact")

                    settingsCard {
                        supportRow(
                            icon: "envelope.fill",
                            iconColor: MatchaTokens.Colors.success,
                            title: "Email Support",
                            subtitle: "hello@matcha.app",
                            action: { openMail() }
                        )

                        cardDivider

                        supportRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            iconColor: Color(hex: 0x7EB2FF),
                            title: "Live Chat",
                            subtitle: "Available Mon–Fri, 9am–6pm",
                            action: {}
                        )

                        cardDivider

                        supportRow(
                            icon: "ant.fill",
                            iconColor: MatchaTokens.Colors.danger,
                            title: "Report a Bug",
                            subtitle: "Help us improve the app",
                            action: {}
                        )
                    }
                }

                // Legal
                VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
                    sectionLabel("Legal")

                    settingsCard {
                        supportRow(
                            icon: "doc.text.fill",
                            iconColor: MatchaTokens.Colors.textSecondary,
                            title: "Terms of Service",
                            subtitle: nil,
                            action: {}
                        )

                        cardDivider

                        supportRow(
                            icon: "lock.shield.fill",
                            iconColor: MatchaTokens.Colors.textSecondary,
                            title: "Privacy Policy",
                            subtitle: nil,
                            action: {}
                        )
                    }
                }

                // App Info
                VStack(spacing: 8) {
                    Text("MATCHA")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .tracking(2)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)

                    Text("Made with love in Bali 🌴")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, MatchaTokens.Spacing.small)
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.large)
            .padding(.bottom, 32)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func supportRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
        }
    }

    private func openMail() {
        if let url = URL(string: "mailto:hello@matcha.app") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ProfileSettingsListView (Full Settings Screen)

/// Pushed from ProfileView — shows all settings rows + sign out.
struct ProfileSettingsListView: View {
    let settingsRows: [SettingsRow]
    var onSignOut: (() -> Void)?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                // Settings rows
                VStack(spacing: 0) {
                    ForEach(Array(settingsRows.enumerated()), id: \.element.title) { idx, row in
                        NavigationLink {
                            SettingsDetailView(row: row)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(settingsIconColor(for: row.title).opacity(0.15))
                                        .frame(width: 30, height: 30)
                                    Image(systemName: row.icon)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(settingsIconColor(for: row.title))
                                }

                                Text(row.title)
                                    .font(.body)
                                    .foregroundStyle(MatchaTokens.Colors.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(row.title)
                        .accessibilityHint("Open \(row.title.lowercased()) settings")

                        if idx < settingsRows.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(
                    MatchaTokens.Colors.surface,
                    in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                )

                // Sign Out
                Button(action: { onSignOut?() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.medium))
                        Text("Sign Out")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(MatchaTokens.Colors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        MatchaTokens.Colors.danger.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .accessibilityLabel("Sign out")
                .accessibilityHint("Sign out of your MATCHA account")
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.large)
            .padding(.bottom, 32)
        }
        .background(MatchaTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func settingsIconColor(for title: String) -> Color {
        switch title {
        case "Subscription":  MatchaTokens.Colors.accent
        case "Account":       Color(hex: 0x7EB2FF)
        case "Notifications": MatchaTokens.Colors.warning
        case "Privacy":       MatchaTokens.Colors.success
        case "Support":       Color(hex: 0xC084FC)
        default:              MatchaTokens.Colors.textSecondary
        }
    }
}

// MARK: - Shared Helpers

private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 0) {
        content()
    }
    .background(
        MatchaTokens.Colors.surface,
        in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
    )
}

private var cardDivider: some View {
    Divider()
        .background(MatchaTokens.Colors.outline)
        .padding(.leading, MatchaTokens.Spacing.large + 34)
}

private func sectionLabel(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundStyle(MatchaTokens.Colors.textSecondary)
        .tracking(1.2)
}

// MARK: - Delete Account Step

enum DeleteAccountStep {
    case none
    case activeDealsWarning
    case confirmDialog
    case typeConfirm
    case gracePeriodInfo
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"
    case bahasaIndonesia = "id"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .russian: "Russian"
        case .bahasaIndonesia: "Bahasa Indonesia"
        }
    }
}
