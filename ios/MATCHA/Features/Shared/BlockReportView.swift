import SwiftUI

// MARK: - BlockReportView

/// Sheet for blocking or reporting another user.
/// Presented from ChatConversationView and ProfileDetailView via three-dot menu.
struct BlockReportView: View {
    let profile: UserProfile
    var onBlock: (() -> Void)? = nil
    var onReport: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode? = nil
    @State private var showBlockConfirm = false

    // Report form state
    @State private var selectedReason: ReportReason? = nil
    @State private var additionalText = ""
    @State private var reportSubmitted = false

    enum Mode { case block, report }

    enum ReportReason: String, CaseIterable, Identifiable {
        case fakeProfile    = "Fake profile"
        case spam           = "Spam"
        case offensive      = "Offensive behavior"
        case noShow         = "No-show"
        case other          = "Other"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .fakeProfile: "person.fill.questionmark"
            case .spam:        "envelope.badge.fill"
            case .offensive:   "hand.raised.fill"
            case .noShow:      "calendar.badge.minus"
            case .other:       "ellipsis.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MatchaTokens.backgroundGradient
                    .ignoresSafeArea()

                if reportSubmitted {
                    reportSuccessView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Block or Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }
            .toolbarBackground(MatchaTokens.Colors.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(MatchaTokens.Colors.background)
        .confirmationDialog(
            "Block \(profile.name)?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                dismiss()
                onBlock?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(profile.name) won't be able to see your profile or contact you. They won't be notified.")
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.top, MatchaTokens.Spacing.large)
                    .padding(.bottom, MatchaTokens.Spacing.medium)

                if mode == nil {
                    selectionButtons
                        .padding(.horizontal, MatchaTokens.Spacing.large)
                } else if mode == .block {
                    blockConfirmSection
                        .padding(.horizontal, MatchaTokens.Spacing.large)
                } else if mode == .report {
                    reportForm
                        .padding(.horizontal, MatchaTokens.Spacing.large)
                }
            }
        }
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: MatchaTokens.Spacing.small) {
            // Avatar
            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.elevated)
                    .frame(width: 72, height: 72)

                if let url = profile.photoURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                        } else {
                            initialsCircle
                        }
                    }
                } else {
                    initialsCircle
                }
            }

            Text(profile.name)
                .font(.headline)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Text(profile.secondaryLine)
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var initialsCircle: some View {
        Text(String(profile.name.prefix(1)).uppercased())
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(MatchaTokens.Colors.accent)
    }

    // MARK: - Selection buttons

    private var selectionButtons: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            // Block option
            actionCard(
                icon: "slash.circle.fill",
                iconColor: MatchaTokens.Colors.danger,
                title: "Block \(profile.name)",
                subtitle: "They won't see your profile or messages",
                action: { withAnimation(MatchaTokens.Animations.sheetPresent) { mode = .block } }
            )

            // Report option
            actionCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: MatchaTokens.Colors.warning,
                title: "Report \(profile.name)",
                subtitle: "Tell us what went wrong",
                action: { withAnimation(MatchaTokens.Animations.sheetPresent) { mode = .report } }
            )
        }
    }

    private func actionCard(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.5))
            }
            .padding(MatchaTokens.Spacing.medium)
            .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Block confirm section

    private var blockConfirmSection: some View {
        VStack(spacing: MatchaTokens.Spacing.large) {
            // Info box
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("When you block someone:")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    Text("• They won't see your profile\n• Your match and messages will be removed\n• They won't be notified")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .padding(MatchaTokens.Spacing.medium)
            .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )

            // Block CTA
            Button(action: { showBlockConfirm = true }) {
                Text("Block \(profile.name)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatchaTokens.Colors.danger, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)

            // Back
            Button(action: { withAnimation(MatchaTokens.Animations.sheetPresent) { mode = nil } }) {
                Text("Go back")
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }
        }
    }

    // MARK: - Report form

    private var reportForm: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.large) {
            Text("What's the issue?")
                .font(.headline)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            // Reason picker
            VStack(spacing: MatchaTokens.Spacing.xSmall) {
                ForEach(ReportReason.allCases) { reason in
                    reasonRow(reason)
                }
            }

            // Optional additional info
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional details (optional)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)

                ZStack(alignment: .topLeading) {
                    if additionalText.isEmpty {
                        Text("Describe what happened…")
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.45))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                    }

                    TextEditor(text: $additionalText)
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 90)
                }
                .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                )
            }

            // Submit
            Button(action: submitReport) {
                Text("Submit Report")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedReason != nil
                            ? MatchaTokens.Colors.accent
                            : MatchaTokens.Colors.elevated,
                        in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedReason == nil)

            // Back
            Button(action: { withAnimation(MatchaTokens.Animations.sheetPresent) { mode = nil } }) {
                Text("Go back")
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }

            Spacer(minLength: MatchaTokens.Spacing.large)
        }
    }

    private func reasonRow(_ reason: ReportReason) -> some View {
        let isSelected = selectedReason == reason
        return Button(action: {
            withAnimation(MatchaTokens.Animations.buttonPress) {
                selectedReason = reason
            }
        }) {
            HStack(spacing: 14) {
                Image(systemName: reason.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
                    .frame(width: 24)

                Text(reason.rawValue)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? MatchaTokens.Colors.textPrimary : MatchaTokens.Colors.textSecondary)

                Spacer()

                // Radio indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                            lineWidth: isSelected ? 0 : 1.5
                        )
                        .frame(width: 22, height: 22)
                        .background(
                            isSelected ? MatchaTokens.Colors.accent : Color.clear,
                            in: Circle()
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? MatchaTokens.Colors.accent.opacity(0.10)
                    : MatchaTokens.Colors.surface,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? MatchaTokens.Colors.accent.opacity(0.4) : MatchaTokens.Colors.outline,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Report success

    private var reportSuccessView: some View {
        VStack(spacing: MatchaTokens.Spacing.large) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.accent.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            VStack(spacing: MatchaTokens.Spacing.small) {
                Text("Report Submitted")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                Text("Thanks for letting us know. We'll review the report and take appropriate action.")
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MatchaTokens.Spacing.xLarge)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.bottom, MatchaTokens.Spacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func submitReport() {
        guard selectedReason != nil else { return }
        withAnimation(MatchaTokens.Animations.sheetPresent) {
            reportSubmitted = true
        }
        onReport?()
    }
}

// MARK: - Preview

#Preview {
    BlockReportView(
        profile: UserProfile(
            id: UUID(),
            name: "Mika Tanaka",
            role: .blogger,
            heroSymbol: "person.crop.circle",
            countryCode: "JP",
            audience: "45K",
            category: nil,
            district: "Seminyak",
            niches: ["Travel", "Lifestyle"],
            languages: ["English", "Japanese"],
            bio: "Travel blogger based in Bali.",
            collaborationType: .both,
            rating: 4.8,
            verifiedVisits: 12,
            badges: [],
            subscriptionPlan: .free,
            hasActiveOffer: false,
            isVerified: true
        )
    )
    .preferredColorScheme(.dark)
}
