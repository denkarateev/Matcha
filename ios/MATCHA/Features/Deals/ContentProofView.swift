import SwiftUI
import PhotosUI

// MARK: - ContentProofView

struct ContentProofView: View {
    let deal: Deal
    var onSubmit: (ContentProof) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var contentURL: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var screenshotImage: UIImage?
    @State private var isSubmitting: Bool = false
    @State private var showURLError: Bool = false
    @FocusState private var urlFocused: Bool

    private var isValidURL: Bool {
        let trimmed = contentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let urlString = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"
        return URL(string: urlString) != nil
    }

    private var canSubmit: Bool {
        isValidURL || screenshotImage != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MatchaTokens.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MatchaTokens.Spacing.large) {
                        headerCard
                        urlSection
                        orDivider
                        screenshotSection
                        requirementNote
                        submitButton
                    }
                    .padding(.horizontal, MatchaTokens.Spacing.large)
                    .padding(.top, MatchaTokens.Spacing.medium)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Content Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(newItem)
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0x7EB2FF).opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "photo.badge.checkmark.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: 0x7EB2FF))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Submit your content")
                    .font(MatchaTokens.Typography.headline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                Text("Deal with \(deal.partnerName)")
                    .font(MatchaTokens.Typography.footnote)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(MatchaTokens.Spacing.medium)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
        )
    }

    // MARK: - URL Section

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                sectionLabel("Content URL")
            }

            HStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.body)
                    .foregroundStyle(
                        urlFocused
                            ? MatchaTokens.Colors.accent
                            : MatchaTokens.Colors.textSecondary
                    )
                    .animation(MatchaTokens.Animations.buttonPress, value: urlFocused)

                TextField("instagram.com/p/...", text: $contentURL)
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .focused($urlFocused)
                    .onChange(of: contentURL) { _, _ in showURLError = false }

                if !contentURL.isEmpty {
                    Button {
                        contentURL = ""
                        showURLError = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.medium)
            .padding(.vertical, 14)
            .background(
                MatchaTokens.Colors.elevated,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        showURLError
                            ? MatchaTokens.Colors.danger.opacity(0.6)
                            : urlFocused
                                ? MatchaTokens.Colors.accent.opacity(0.5)
                                : MatchaTokens.Colors.outline,
                        lineWidth: 1
                    )
            )
            .animation(MatchaTokens.Animations.buttonPress, value: urlFocused)

            if showURLError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MatchaTokens.Colors.danger)
                    Text("Please enter a valid URL")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.danger)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Accepted platforms
            HStack(spacing: 8) {
                Text("Accepted:")
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                ForEach(["Instagram", "TikTok", "YouTube", "Other"], id: \.self) { platform in
                    Text(platform)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MatchaTokens.Colors.elevated, in: Capsule())
                }
            }
        }
    }

    // MARK: - OR Divider

    private var orDivider: some View {
        HStack(spacing: MatchaTokens.Spacing.medium) {
            Rectangle()
                .fill(MatchaTokens.Colors.outline)
                .frame(height: 1)
            Text("OR")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)
            Rectangle()
                .fill(MatchaTokens.Colors.outline)
                .frame(height: 1)
        }
    }

    // MARK: - Screenshot Section

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            HStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x7EB2FF))
                sectionLabel("Screenshot")
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(MatchaTokens.Colors.elevated, in: Capsule())
            }

            if let image = screenshotImage {
                // Image preview
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(MatchaTokens.Colors.accent.opacity(0.3), lineWidth: 1)
                        )

                    Button {
                        withAnimation { screenshotImage = nil; selectedPhotoItem = nil }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(MatchaTokens.Colors.surface)
                                .frame(width: 28, height: 28)
                            Image(systemName: "xmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                        }
                    }
                    .padding(8)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Picker button
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: 0x7EB2FF).opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: "photo.badge.plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color(hex: 0x7EB2FF))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Screenshot")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                            Text("Upload a screenshot of your published post")
                                .font(.caption)
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.5))
                    }
                    .padding(MatchaTokens.Spacing.medium)
                    .background(
                        MatchaTokens.Colors.elevated,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                    )
                }
            }
        }
        .animation(MatchaTokens.Animations.cardAppear, value: screenshotImage != nil)
    }

    // MARK: - Requirement Note

    private var requirementNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.body)
                .foregroundStyle(Color(hex: 0x7EB2FF).opacity(0.7))
            Text("Submit at least a URL or a screenshot. The business will review and confirm your content proof.")
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(MatchaTokens.Spacing.medium)
        .background(
            Color(hex: 0x7EB2FF).opacity(0.06),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: 0x7EB2FF).opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button(action: submitProof) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(MatchaTokens.Colors.background)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.body.weight(.semibold))
                    Text("Submit Proof")
                        .font(MatchaTokens.Typography.headline)
                }
            }
            .foregroundStyle(MatchaTokens.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                canSubmit
                    ? MatchaTokens.Colors.accent
                    : MatchaTokens.Colors.accentMuted.opacity(0.4),
                in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
            )
        }
        .disabled(!canSubmit || isSubmitting)
        .animation(MatchaTokens.Animations.buttonPress, value: canSubmit)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(MatchaTokens.Colors.textSecondary)
            .tracking(1.0)
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation { screenshotImage = image }
                }
            }
        }
    }

    private func submitProof() {
        let trimmed = contentURL.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty && !isValidURL {
            withAnimation { showURLError = true }
            return
        }

        guard canSubmit else { return }
        isSubmitting = true

        let proof = ContentProof(
            url: trimmed.isEmpty ? "" : (trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"),
            screenshotPath: screenshotImage != nil ? "local_screenshot" : nil,
            submittedAt: Date()
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSubmitting = false
            onSubmit(proof)
            dismiss()
        }
    }
}
