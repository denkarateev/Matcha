import SwiftUI

// MARK: - SubscriptionView

struct SubscriptionView: View {
    @State private var showPaywall = false
    @Environment(\.dismiss) private var dismiss

    private var store: StoreManager { StoreManager.shared }
    private var currentPlan: SubscriptionPlan { store.currentPlan }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: MatchaTokens.Spacing.large) {
                currentPlanCard
                welcomeBoostBanner
                featuresList
                if currentPlan != .black {
                    upgradeSection
                }
                billingInfo
                manageLink
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.top, MatchaTokens.Spacing.medium)
            .padding(.bottom, 40)
        }
        .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView(.general)
        }
        .task {
            await store.updateSubscriptionStatus()
        }
    }

    // MARK: - Current Plan Card

    private var currentPlanCard: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            // Plan badge
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                planAccentColor.opacity(0.3),
                                planAccentColor.opacity(0.05),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: planIcon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(planAccentColor)
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text("MATCHA \(currentPlan.title)")
                        .font(MatchaTokens.Typography.title1)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MatchaTokens.Colors.success, in: Capsule())
                }

                Text(planDescription)
                    .font(MatchaTokens.Typography.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MatchaTokens.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [planAccentColor.opacity(0.4), planAccentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Welcome Boost Banner

    @ViewBuilder
    private var welcomeBoostBanner: some View {
        if store.isWelcomeBoostActive {
            HStack(spacing: MatchaTokens.Spacing.small) {
                Image(systemName: "bolt.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(MatchaTokens.Colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("7-day Pro Trial")
                        .font(MatchaTokens.Typography.headline)
                        .foregroundStyle(MatchaTokens.Colors.textPrimary)

                    Text("\(store.welcomeBoostDaysLeft) days left")
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.5))
            }
            .padding(MatchaTokens.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .fill(MatchaTokens.Colors.accent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Features List

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            Text("YOUR FEATURES")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)

            VStack(spacing: 0) {
                ForEach(Array(currentFeatures.enumerated()), id: \.offset) { index, feature in
                    featureRow(feature)

                    if index < currentFeatures.count - 1 {
                        Divider()
                            .background(MatchaTokens.Colors.outline)
                            .padding(.leading, 48)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .fill(MatchaTokens.Colors.surface)
            )
        }
    }

    private func featureRow(_ feature: PlanFeature) -> some View {
        HStack(spacing: MatchaTokens.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(feature.included ? MatchaTokens.Colors.accent.opacity(0.12) : MatchaTokens.Colors.elevated)
                    .frame(width: 32, height: 32)
                Image(systemName: feature.included ? "checkmark" : "lock")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(feature.included ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(MatchaTokens.Typography.subheadline)
                    .foregroundStyle(feature.included ? MatchaTokens.Colors.textPrimary : MatchaTokens.Colors.textSecondary.opacity(0.5))

                if let detail = feature.detail {
                    Text(detail)
                        .font(MatchaTokens.Typography.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 12)
    }

    // MARK: - Upgrade Section

    private var upgradeSection: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            let nextTier = currentPlan == .free ? SubscriptionPlan.pro : .black

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.body.weight(.semibold))
                    Text("Upgrade to \(nextTier.title)")
                        .font(.headline)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    MatchaTokens.Colors.accent,
                    in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                )
                .matchaShadow(MatchaTokens.Shadow.level1)
            }
            .buttonStyle(.plain)

            if currentPlan == .pro {
                Button {
                    showPaywall = true
                } label: {
                    Text("Downgrade to Free")
                        .font(MatchaTokens.Typography.footnote)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        .underline()
                }
            }
        }
    }

    // MARK: - Billing Info

    private var billingInfo: some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.small) {
            Text("BILLING")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)

            VStack(spacing: 0) {
                billingRow(label: "Plan", value: "MATCHA \(currentPlan.title)")
                Divider().background(MatchaTokens.Colors.outline).padding(.leading, 16)
                billingRow(label: "Price", value: billingPrice)
                Divider().background(MatchaTokens.Colors.outline).padding(.leading, 16)
                billingRow(label: "Renewal", value: currentPlan == .free ? "N/A" : "Auto-renew monthly")
                Divider().background(MatchaTokens.Colors.outline).padding(.leading, 16)
                billingRow(label: "Payment", value: currentPlan == .free ? "N/A" : "Apple ID")
            }
            .background(
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .fill(MatchaTokens.Colors.surface)
            )
        }
    }

    private var billingPrice: String {
        if currentPlan == .free {
            return store.isWelcomeBoostActive ? "Free (Pro trial)" : "Free"
        }
        if let product = store.product(for: currentPlan) {
            return "\(product.displayPrice)/month"
        }
        return currentPlan == .pro ? "$14.99/month" : "$29.99/month"
    }

    private func billingRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(MatchaTokens.Typography.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(MatchaTokens.Typography.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
    }

    // MARK: - Manage Link

    private var manageLink: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.body)
                Text("Manage in App Store")
                    .font(MatchaTokens.Typography.subheadline)
            }
            .foregroundStyle(MatchaTokens.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                MatchaTokens.Colors.surface,
                in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var planIcon: String {
        switch currentPlan {
        case .free: "leaf.fill"
        case .pro: "crown.fill"
        case .black: "star.circle.fill"
        }
    }

    private var planAccentColor: Color {
        switch currentPlan {
        case .free: MatchaTokens.Colors.textSecondary
        case .pro: MatchaTokens.Colors.accent
        case .black: MatchaTokens.Colors.warning
        }
    }

    private var planDescription: String {
        switch currentPlan {
        case .free: "Basic access to MATCHA"
        case .pro: "Unlimited swipes and premium features"
        case .black: "The ultimate MATCHA experience"
        }
    }

    private var currentFeatures: [PlanFeature] {
        let allFeatures: [(String, String?, Bool, Bool, Bool)] = [
            // (title, detail, free, pro, black)
            ("Daily swipes", "10/day on Free, unlimited on Pro+", true, true, true),
            ("Basic filters", nil, true, true, true),
            ("Unlimited swipes", nil, false, true, true),
            ("See who likes you", nil, false, true, true),
            ("Offer Credits", "3/week on Pro, 7/week on Black", false, true, true),
            ("Full filters", nil, false, true, true),
            ("Quick Replies", nil, false, true, true),
            ("Last Minute offers", nil, false, false, true),
            ("Repeat Collab", nil, false, false, true),
            ("+30% profile boost", nil, false, false, true),
            ("Priority support", nil, false, false, true),
        ]

        return allFeatures.map { title, detail, free, pro, black in
            let included: Bool = switch currentPlan {
            case .free: free
            case .pro: pro
            case .black: black
            }
            return PlanFeature(title: title, detail: detail, included: included)
        }
    }
}

// MARK: - PlanFeature

private struct PlanFeature {
    let title: String
    let detail: String?
    let included: Bool
}

// MARK: - Preview

#Preview("Free Plan") {
    NavigationStack {
        SubscriptionView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Pro Plan") {
    NavigationStack {
        SubscriptionView()
    }
    .preferredColorScheme(.dark)
}
