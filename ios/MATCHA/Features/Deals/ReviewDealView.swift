import SwiftUI

// MARK: - ReviewDealView

struct ReviewDealView: View {
    let deal: Deal
    var onSubmit: (DealReview) -> Void

    @Environment(\.dismiss) private var dismiss

    // Star ratings
    @State private var punctuality: Int = 0
    @State private var offerMatch: Int = 0
    @State private var communication: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting: Bool = false
    @FocusState private var commentFocused: Bool

    private var isValid: Bool {
        punctuality > 0 && offerMatch > 0 && communication > 0
    }

    private var averageRating: Double {
        guard punctuality > 0, offerMatch > 0, communication > 0 else { return 0 }
        return Double(punctuality + offerMatch + communication) / 3.0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MatchaTokens.backgroundGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MatchaTokens.Spacing.large) {
                        headerCard
                        criteriaSection
                        commentSection
                        if isValid { ratingPreview }
                        submitButton
                        privacyNote
                    }
                    .padding(.horizontal, MatchaTokens.Spacing.large)
                    .padding(.top, MatchaTokens.Spacing.medium)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: MatchaTokens.Spacing.small) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MatchaTokens.Colors.warning.opacity(0.2), MatchaTokens.Colors.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "star.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(MatchaTokens.Colors.warning)
            }

            Text("Rate your experience")
                .font(MatchaTokens.Typography.title2)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Text("with \(deal.partnerName)")
                .font(.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MatchaTokens.Spacing.large)
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
    }

    // MARK: - Criteria

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            sectionLabel("Rate Each Category")

            VStack(spacing: 0) {
                criteriaRow(
                    icon: "clock.fill",
                    iconColor: MatchaTokens.Colors.accent,
                    title: "Punctuality",
                    subtitle: "Arrived on time, smooth timing",
                    rating: $punctuality
                )

                Divider()
                    .background(MatchaTokens.Colors.outline)
                    .padding(.leading, 56)

                criteriaRow(
                    icon: "gift.fill",
                    iconColor: Color(hex: 0x7EB2FF),
                    title: "Offer Match",
                    subtitle: "The deal matched what was agreed",
                    rating: $offerMatch
                )

                Divider()
                    .background(MatchaTokens.Colors.outline)
                    .padding(.leading, 56)

                criteriaRow(
                    icon: "message.fill",
                    iconColor: MatchaTokens.Colors.success,
                    title: "Communication",
                    subtitle: "Clear, responsive, professional",
                    rating: $communication
                )
            }
            .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        }
    }

    private func criteriaRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        rating: Binding<Int>
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }

            Spacer()

            StarRatingPicker(rating: rating, color: iconColor)
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, MatchaTokens.Spacing.medium)
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            HStack(spacing: 8) {
                sectionLabel("Comment")
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(MatchaTokens.Colors.elevated, in: Capsule())
                Spacer()
                Text("\(comment.count)/300")
                    .font(.caption2)
                    .foregroundStyle(
                        comment.count > 270
                            ? MatchaTokens.Colors.warning
                            : MatchaTokens.Colors.textSecondary.opacity(0.5)
                    )
            }

            ZStack(alignment: .topLeading) {
                if comment.isEmpty {
                    Text("Share your experience — what stood out, what could be better...")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.4))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $comment)
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($commentFocused)
                    .frame(minHeight: 90, maxHeight: 150)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .onChange(of: comment) { _, newValue in
                        if newValue.count > 300 {
                            comment = String(newValue.prefix(300))
                        }
                    }
            }
            .background(
                MatchaTokens.Colors.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        commentFocused
                            ? MatchaTokens.Colors.accent.opacity(0.5)
                            : MatchaTokens.Colors.outline,
                        lineWidth: 1
                    )
            )
            .animation(MatchaTokens.Animations.buttonPress, value: commentFocused)
        }
    }

    // MARK: - Rating Preview

    private var ratingPreview: some View {
        HStack(spacing: MatchaTokens.Spacing.medium) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", averageRating))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(MatchaTokens.Colors.warning)

                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= Int(averageRating.rounded()) ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(MatchaTokens.Colors.warning)
                    }
                }

                Text("Average")
                    .font(.caption2)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
            }

            Divider()
                .frame(height: 56)
                .background(MatchaTokens.Colors.outline)

            VStack(alignment: .leading, spacing: 6) {
                miniRatingRow(label: "Punctuality", value: punctuality, color: MatchaTokens.Colors.accent)
                miniRatingRow(label: "Offer Match", value: offerMatch, color: Color(hex: 0x7EB2FF))
                miniRatingRow(label: "Communication", value: communication, color: MatchaTokens.Colors.success)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(MatchaTokens.Spacing.medium)
        .background(MatchaTokens.Colors.surface, in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.warning.opacity(0.2), lineWidth: 1)
        )
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }

    private func miniRatingRow(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .frame(width: 90, alignment: .leading)

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? color : MatchaTokens.Colors.outline)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button(action: submitReview) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(MatchaTokens.Colors.background)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "star.bubble.fill")
                        .font(.body.weight(.semibold))
                    Text("Submit Review")
                        .font(MatchaTokens.Typography.headline)
                }
            }
            .foregroundStyle(MatchaTokens.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                isValid
                    ? MatchaTokens.Colors.accent
                    : MatchaTokens.Colors.accentMuted.opacity(0.4),
                in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
            )
        }
        .disabled(!isValid || isSubmitting)
        .animation(MatchaTokens.Animations.buttonPress, value: isValid)
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption2)
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.5))
            Text("Reviews are hidden until both parties submit, or after 7 days.")
                .font(.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                .multilineTextAlignment(.leading)
        }
        .padding(.top, -MatchaTokens.Spacing.small)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(MatchaTokens.Colors.textSecondary)
            .tracking(1.0)
    }

    private func submitReview() {
        guard isValid else { return }
        isSubmitting = true

        let review = DealReview(
            punctuality: punctuality,
            offerMatch: offerMatch,
            communication: communication,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : comment.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSubmitting = false
            onSubmit(review)
            dismiss()
        }
    }
}

// MARK: - StarRatingPicker

private struct StarRatingPicker: View {
    @Binding var rating: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Button {
                    withAnimation(MatchaTokens.Animations.buttonPress) { rating = i }
                } label: {
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(i <= rating ? color : MatchaTokens.Colors.outline)
                        .scaleEffect(i <= rating ? 1.0 : 0.9)
                        .animation(MatchaTokens.Animations.buttonPress, value: rating)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
