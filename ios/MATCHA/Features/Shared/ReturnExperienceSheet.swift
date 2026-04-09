import SwiftUI

// MARK: - ReturnExperienceSheet (spec 20)

/// Bottom sheet shown when user returns after 3+ days of inactivity.
/// Displays up to 3 relevant engagement metrics with CTAs.
/// Priority order: Likes > Offers > Profiles.
/// Not shown if all metrics are zero.
struct ReturnExperienceSheet: View {
    let metrics: ReturnMetrics
    var onAction: (ReturnAction) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    private var visibleItems: [ReturnItem] {
        var items: [ReturnItem] = []

        if metrics.newLikes > 0 {
            items.append(ReturnItem(
                icon: "heart.fill",
                iconColor: MatchaTokens.Colors.danger,
                message: "\(metrics.newLikes) new \(metrics.newLikes == 1 ? "person" : "people") liked you while you were away",
                actionLabel: "See Likes",
                action: .seeLikes
            ))
        }

        if metrics.newOffers > 0 {
            items.append(ReturnItem(
                icon: "tag.fill",
                iconColor: MatchaTokens.Colors.warning,
                message: "\(metrics.newOffers) new \(metrics.newOffers == 1 ? "offer" : "offers") in your niches",
                actionLabel: "Open Offers",
                action: .openOffers
            ))
        }

        if metrics.newProfiles > 0 {
            items.append(ReturnItem(
                icon: "person.2.fill",
                iconColor: MatchaTokens.Colors.baliBlue,
                message: "\(metrics.newProfiles) new \(metrics.newProfiles == 1 ? "profile" : "profiles") joined",
                actionLabel: "Start Matching",
                action: .startMatching
            ))
        }

        return Array(items.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 20)

            // Header
            VStack(spacing: 8) {
                Text("Welcome back!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Here's what happened while you were away")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.bottom, 24)

            // Metric rows
            VStack(spacing: 12) {
                ForEach(visibleItems) { item in
                    returnItemRow(item)
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 24)

            // Dismiss button
            Button {
                onDismiss()
                dismiss()
            } label: {
                Text("Got it")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(MatchaTokens.Colors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: - Row

    private func returnItemRow(_ item: ReturnItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                onAction(item.action)
                dismiss()
            } label: {
                Text(item.actionLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(MatchaTokens.Colors.accent, in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}

// MARK: - Supporting Types

struct ReturnMetrics {
    var newLikes: Int = 0
    var newOffers: Int = 0
    var newProfiles: Int = 0

    var hasAnyActivity: Bool {
        newLikes > 0 || newOffers > 0 || newProfiles > 0
    }
}

enum ReturnAction {
    case seeLikes
    case openOffers
    case startMatching
}

private struct ReturnItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let message: String
    let actionLabel: String
    let action: ReturnAction
}

// MARK: - Preview

#Preview {
    Color.black
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            ReturnExperienceSheet(
                metrics: ReturnMetrics(
                    newLikes: 5,
                    newOffers: 3,
                    newProfiles: 8
                )
            )
        }
}
