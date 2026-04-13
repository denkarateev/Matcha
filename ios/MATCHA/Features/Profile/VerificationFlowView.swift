import PhotosUI
import SwiftUI

// MARK: - VerificationFlowView

/// 3-step verification wizard presented as a sheet.
/// Step 1: Photos + Niches
/// Step 2: Audience (role-dependent)
/// Step 3: Social Bridge (Instagram DM code verification)
struct VerificationFlowView: View {
    var profile: UserProfile?
    var onSubmitted: () -> Void = {}
    @State private var loadedProfile: UserProfile?

    @State private var currentStep = 1
    @Environment(\.dismiss) private var dismiss

    // MARK: Step 1 — Photos + Niches
    @State private var additionalPhotos: [PhotoSlot] = []
    @State private var selectedNiches: Set<String> = []

    // MARK: Step 2 — Audience
    @State private var audienceSize: AudienceTier = .nano
    @State private var businessDistrict: String = ""

    // MARK: Step 3 — Social Bridge
    @State private var instagramHandle: String = ""
    @State private var tiktokHandle: String = ""
    @State private var verificationCode: String = ""
    @State private var screenshotItem: PhotosPickerItem?
    @State private var screenshotImage: Image?

    // UI state
    @State private var isSubmitting = false
    @State private var showSuccess = false

    private let totalSteps = 3

    private let allNiches = [
        "Food & Drink", "Travel", "Wellness & Fitness",
        "Beauty & Fashion", "Lifestyle", "Family & Kids",
        "Pets", "Art & Design", "Business & Tech",
        "Eco & Sustainable", "Events & Nightlife",
    ]

    init(profile: UserProfile? = nil, onSubmitted: @escaping () -> Void = {}) {
        self.profile = profile
        self.onSubmitted = onSubmitted
        _selectedNiches = State(initialValue: Set(profile?.niches ?? []))
        _instagramHandle = State(initialValue: "")
        _tiktokHandle = State(initialValue: "")
        _verificationCode = State(initialValue: Self.generateCode())
        _businessDistrict = State(initialValue: profile?.district ?? profile?.locationDistrict ?? "")
    }

    /// Resolved profile — uses loaded from API if available, falls back to passed profile
    private var activeProfile: UserProfile {
        loadedProfile ?? profile ?? UserProfile(
            id: UUID(), name: "", role: .blogger, heroSymbol: "",
            countryCode: "ID", audience: "", category: nil, district: nil,
            niches: [], languages: [], bio: "", collaborationType: .both,
            rating: nil, verifiedVisits: 0, badges: [], subscriptionPlan: .free,
            hasActiveOffer: false, isVerified: false
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showSuccess {
                    successView
                        .transition(.opacity)
                } else {
                    // Progress bar
                    verificationProgressBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    // Step content
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            switch currentStep {
                            case 1: step1PhotosNiches
                            case 2: step2Audience
                            case 3: step3SocialBridge
                            default: EmptyView()
                            }

                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 24)
                    }
                    .scrollBounceBehavior(.basedOnSize)

                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: currentStep)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSuccess)
        }
    }

    // MARK: - Progress Bar (3 segments)

    private var verificationProgressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? MatchaTokens.Colors.accent : Color.white.opacity(0.1))
                        .frame(height: 3)
                }
            }

            Text("Step \(currentStep) of \(totalSteps)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Step 1: Photos + Niches

    private var step1PhotosNiches: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section header
            VStack(alignment: .leading, spacing: 6) {
                Text("Photos & Niches")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Add more photos and select your niches to get verified")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 16)

            // Additional photos
            verificationSection(title: "ADDITIONAL PHOTOS", subtitle: "Optional, up to 5") {
                PhotoGridView(photos: $additionalPhotos)
            }

            // Niches (required)
            verificationSection(title: "NICHES", subtitle: "Select up to 5 (required)") {
                VStack(alignment: .leading, spacing: 10) {
                    FlowLayout(spacing: 8) {
                        ForEach(allNiches, id: \.self) { niche in
                            let selected = selectedNiches.contains(niche)
                            Button {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    if selected {
                                        selectedNiches.remove(niche)
                                    } else if selectedNiches.count < 5 {
                                        selectedNiches.insert(niche)
                                    }
                                }
                            } label: {
                                Text(niche)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(selected ? .black : .white.opacity(0.7))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 9)
                                    .background(
                                        selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.08),
                                        in: Capsule()
                                    )
                                    .overlay {
                                        if !selected {
                                            Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                        }
                                    }
                            }
                        }
                    }

                    Text("\(selectedNiches.count)/5 selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(selectedNiches.isEmpty ? MatchaTokens.Colors.danger : .white.opacity(0.3))
                }
            }
        }
    }

    // MARK: - Step 2: Audience

    private var step2Audience: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Audience")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text(activeProfile.role == .blogger
                    ? "Tell us about your audience size"
                    : "Tell us about your business location")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 16)

            if activeProfile.role == .blogger {
                verificationSection(title: "AUDIENCE SIZE") {
                    VStack(spacing: 10) {
                        ForEach([AudienceTier.nano, .micro, .mid], id: \.self) { tier in
                            audienceTierRow(tier)
                        }
                    }
                }
            } else {
                // Business: district text field
                verificationSection(title: "DISTRICT") {
                    TextField("e.g. Seminyak, Canggu, Ubud...", text: $businessDistrict)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                }
            }
        }
    }

    // MARK: - Step 3: Social Bridge

    private var step3SocialBridge: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Social Verification")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Link your social accounts to complete verification")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 16)

            // Instagram handle
            verificationSection(title: "INSTAGRAM", subtitle: "Required") {
                HStack(spacing: 0) {
                    Text("@")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("yourusername", text: $instagramHandle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }

            // Verification code + instructions
            verificationSection(title: "VERIFICATION CODE") {
                VStack(alignment: .leading, spacing: 16) {
                    // Instructions
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                            .frame(width: 24)

                        Text("Send this code to **@matchabali** on Instagram DM")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    // Code display
                    HStack(spacing: 0) {
                        ForEach(Array(verificationCode.enumerated()), id: \.offset) { _, char in
                            Text(String(char))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        MatchaTokens.Colors.accent.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 1)
                    }

                    // Copy button
                    Button {
                        UIPasteboard.general.string = verificationCode
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Copy Code")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            MatchaTokens.Colors.accent.opacity(0.1),
                            in: Capsule()
                        )
                    }
                }
            }

            // Instagram stats screenshot
            verificationSection(title: "INSTAGRAM STATS SCREENSHOT", subtitle: "Required") {
                VStack(spacing: 12) {
                    if let screenshotImage {
                        screenshotImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    PhotosPicker(
                        selection: $screenshotItem,
                        matching: .screenshots
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: screenshotImage == nil ? "photo.badge.plus" : "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                            Text(screenshotImage == nil ? "Choose Screenshot" : "Replace Screenshot")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(MatchaTokens.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            MatchaTokens.Colors.accent.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    MatchaTokens.Colors.accent.opacity(0.2),
                                    style: StrokeStyle(lineWidth: 1.5, dash: screenshotImage == nil ? [8, 5] : [])
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    if screenshotImage == nil {
                        Text("Upload a screenshot of your Instagram insights/stats page")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }

            // TikTok (optional)
            verificationSection(title: "TIKTOK", subtitle: "Optional") {
                HStack(spacing: 0) {
                    Text("@")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                    TextField("yourusername", text: $tiktokHandle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
        }
        .onChange(of: screenshotItem) { _, newItem in
            Task { await loadScreenshot(newItem) }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            // Back button
            if currentStep > 1 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            // Continue / Submit button
            Button {
                if currentStep < totalSteps {
                    withAnimation { currentStep += 1 }
                } else {
                    submitVerification()
                }
            } label: {
                ZStack {
                    if isSubmitting {
                        ProgressView().tint(.black)
                    } else {
                        HStack(spacing: 6) {
                            Text(currentStep < totalSteps ? "Continue" : "Submit for Verification")
                                .font(.system(size: 15, weight: .bold))
                            if currentStep < totalSteps {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                        }
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    canAdvance ? MatchaTokens.Colors.accent : MatchaTokens.Colors.accent.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(!canAdvance || isSubmitting)
        }
        .padding(.top, 8)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MatchaTokens.Colors.accent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            VStack(spacing: 8) {
                Text("Verification Pending")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("We'll notify you when your verification is approved. This usually takes 24-48 hours.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                onSubmitted()
                dismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func verificationSection<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(0.8)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }

                Spacer()
            }

            content()
                .padding(16)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }

    @ViewBuilder
    private func audienceTierRow(_ tier: AudienceTier) -> some View {
        let selected = audienceSize == tier
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { audienceSize = tier }
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .strokeBorder(selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if selected {
                            Circle().fill(MatchaTokens.Colors.accent).frame(width: 12, height: 12)
                        }
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selected ? .white : .white.opacity(0.7))
                    Text(tier.range)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                selected ? MatchaTokens.Colors.accent.opacity(0.08) : Color.white.opacity(0.03),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selected ? MatchaTokens.Colors.accent.opacity(0.3) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
        }
    }

    // MARK: - Validation

    private var canAdvance: Bool {
        switch currentStep {
        case 1:
            return !selectedNiches.isEmpty
        case 2:
            if activeProfile.role == .business {
                return !businessDistrict.trimmingCharacters(in: .whitespaces).isEmpty
            }
            return true // blogger always has a tier selected
        case 3:
            let hasHandle = !instagramHandle.trimmingCharacters(in: .whitespaces).isEmpty
            let hasScreenshot = screenshotImage != nil
            return hasHandle && hasScreenshot
        default:
            return false
        }
    }

    // MARK: - Actions

    private func submitVerification() {
        isSubmitting = true
        // Simulate network call
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                isSubmitting = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showSuccess = true
                }
            }
        }
    }

    private func loadScreenshot(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    screenshotImage = Image(uiImage: uiImage)
                }
            }
        } catch {
            // Silently fail — user can retry
        }
    }

    private static func generateCode() -> String {
        let digits = (0..<6).map { _ in String(Int.random(in: 0...9)) }
        return digits.joined()
    }
}

// MARK: - Preview

#Preview {
    VerificationFlowView(
        profile: MockSeedData.makeCurrentUser(role: .blogger, name: "Preview User")
    )
}
