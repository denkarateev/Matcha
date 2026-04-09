import SwiftUI
import StoreKit

// MARK: - Paywall Trigger

enum PaywallTrigger {
    case swipesExhausted    // "You've used all your daily swipes"
    case blurredLikes       // "3 businesses liked you. Upgrade to see who"
    case offerCredits       // "Create offers to attract top creators"
    case superSwipe         // "Stand out with SuperSwipe"
    case general            // Generic upgrade screen

    var icon: String {
        switch self {
        case .swipesExhausted: "hand.raised.slash.fill"
        case .blurredLikes:    "eye.slash.fill"
        case .offerCredits:    "tag.fill"
        case .superSwipe:      "star.fill"
        case .general:         "crown.fill"
        }
    }

    var headline: String {
        switch self {
        case .swipesExhausted: "You've used all your daily swipes"
        case .blurredLikes:    "3 businesses liked you"
        case .offerCredits:    "Create offers to attract top creators"
        case .superSwipe:      "Stand out with SuperSwipe"
        case .general:         "Unlock the full MATCHA experience"
        }
    }

    var subtitle: String {
        switch self {
        case .swipesExhausted: "Upgrade for unlimited swipes and never miss a match"
        case .blurredLikes:    "Upgrade to see who liked you and connect instantly"
        case .offerCredits:    "Send personalized offers to your top picks"
        case .superSwipe:      "Get noticed 3x faster with SuperSwipe"
        case .general:         "More swipes, more features, more collabs"
        }
    }

    /// Which tier to highlight based on the trigger context.
    var recommendedTier: SubscriptionPlan {
        switch self {
        case .swipesExhausted: .pro
        case .blurredLikes:    .pro
        case .offerCredits:    .black
        case .superSwipe:      .pro
        case .general:         .pro
        }
    }
}

// MARK: - PaywallView

struct PaywallView: View {
    let trigger: PaywallTrigger
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .pro
    @State private var animateIn = false
    @State private var purchaseError: String?
    @State private var showSuccess = false

    private var store: StoreManager { StoreManager.shared }

    init(_ trigger: PaywallTrigger = .general) {
        self.trigger = trigger
        _selectedPlan = State(initialValue: trigger.recommendedTier)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: 0x0A1A0D),
                    MatchaTokens.Colors.background,
                    Color(hex: 0x0D0A15),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MatchaTokens.Spacing.large) {
                    // Spacer for close button area
                    Color.clear.frame(height: 20)

                    triggerHeader
                    currentPlanBadge
                    planCards
                    ctaButton
                    restorePurchaseButton
                    legalFooter
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.bottom, 40)
            }

            // Close button
            closeButton
                .padding(.top, 16)
                .padding(.trailing, MatchaTokens.Spacing.large)
        }
        .task {
            await store.loadProducts()
        }
        .onAppear {
            withAnimation(MatchaTokens.Animations.sheetPresent) {
                animateIn = true
            }
        }
        .alert("Purchase Successful", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Welcome to MATCHA \(selectedPlan.title)! Enjoy your new features.")
        }
        .alert("Purchase Error", isPresented: .init(
            get: { purchaseError != nil },
            set: { if !$0 { purchaseError = nil } }
        )) {
            Button("OK") { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .liquidGlassPill()
        }
    }

    // MARK: - Trigger Header

    private var triggerHeader: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MatchaTokens.Colors.accent.opacity(0.25),
                                MatchaTokens.Colors.accent.opacity(0.05),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: trigger.icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(MatchaTokens.Colors.accent)
                    .symbolEffect(.pulse, options: .repeating, value: animateIn)
            }

            Text(trigger.headline)
                .font(MatchaTokens.Typography.title1)
                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(trigger.subtitle)
                .font(MatchaTokens.Typography.subheadline)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, MatchaTokens.Spacing.large)
    }

    // MARK: - Current Plan Badge

    private var currentPlanBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: store.currentPlan == .free ? "leaf.fill" : "crown.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(
                    store.currentPlan == .free
                        ? MatchaTokens.Colors.textSecondary
                        : MatchaTokens.Colors.accent
                )

            Text("Current plan: \(store.currentPlan.title)")
                .font(MatchaTokens.Typography.caption)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)

            if store.isWelcomeBoostActive {
                Text("Boost \(store.welcomeBoostDaysLeft)d left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(MatchaTokens.Colors.accent, in: Capsule())
            }
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: MatchaTokens.Radius.pill)
    }

    // MARK: - Plan Cards

    private var planCards: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            planCard(for: .free)
            planCard(for: .pro)
            planCard(for: .black)
        }
    }

    private func planCard(for plan: SubscriptionPlan) -> some View {
        let isSelected = selectedPlan == plan
        let isRecommended = trigger.recommendedTier == plan
        let isCurrent = store.currentPlan == plan

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPlan = plan
            }
        } label: {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(plan.title)
                                .font(MatchaTokens.Typography.headline)
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)

                            if isCurrent {
                                Text("Current")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(MatchaTokens.Colors.success, in: Capsule())
                            } else if isRecommended {
                                Text("Recommended")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(MatchaTokens.Colors.accent, in: Capsule())
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(priceText(for: plan))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    plan == .free
                                        ? MatchaTokens.Colors.textSecondary
                                        : MatchaTokens.Colors.accent
                                )
                            Text(billingLabel(for: plan))
                                .font(MatchaTokens.Typography.caption)
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(MatchaTokens.Colors.accent)
                                .frame(width: 14, height: 14)
                        }
                    }
                }

                // Feature list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features(for: plan), id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(
                                    plan == .free
                                        ? MatchaTokens.Colors.textSecondary
                                        : MatchaTokens.Colors.accent
                                )
                                .frame(width: 16)

                            Text(feature)
                                .font(MatchaTokens.Typography.footnote)
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(MatchaTokens.Spacing.medium)
            .liquidGlass()
            .overlay(
                RoundedRectangle(cornerRadius: MatchaTokens.Radius.card, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? MatchaTokens.Colors.accent
                            : Color.clear,
                        lineWidth: isSelected ? 1.5 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pricing Helpers

    private func priceText(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .free:
            return "$0"
        case .pro, .black:
            if let product = store.product(for: plan) {
                return product.displayPrice
            }
            // Fallback while products load
            return plan == .pro ? "$14.99" : "$29.99"
        }
    }

    private func billingLabel(for plan: SubscriptionPlan) -> String {
        guard plan != .free else { return "Forever" }
        return "/month"
    }

    private func features(for plan: SubscriptionPlan) -> [String] {
        switch plan {
        case .free:
            return [
                "10 swipes/day",
                "Basic filters",
                "1 active conversation",
            ]
        case .pro:
            return [
                "Unlimited swipes",
                "See who likes you",
                "3 Offer Credits/week",
                "Full filters",
                "Quick Replies",
            ]
        case .black:
            return [
                "All Pro features",
                "7 Offer Credits/week",
                "Last Minute offers",
                "Repeat Collab",
                "+30% profile boost",
                "Priority support",
            ]
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button {
            if selectedPlan == .free {
                dismiss()
            } else {
                Task { await handlePurchase() }
            }
        } label: {
            HStack(spacing: 10) {
                if store.isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: selectedPlan == .free ? "checkmark.circle.fill" : "sparkles")
                        .font(.body.weight(.semibold))

                    Text(ctaTitle)
                        .font(.headline)
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                MatchaTokens.Colors.accent,
                in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
            )
            .matchaShadow(MatchaTokens.Shadow.level2)
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedPlan)
    }

    private var ctaTitle: String {
        if selectedPlan == .free {
            return "Continue with Free"
        }
        if store.currentPlan == selectedPlan {
            return "Already Subscribed"
        }
        return "Subscribe to \(selectedPlan.title)"
    }

    private func handlePurchase() async {
        guard let product = store.product(for: selectedPlan) else {
            purchaseError = "Product not available. Please try again later."
            return
        }

        do {
            let transaction = try await store.purchase(product)
            if transaction != nil {
                showSuccess = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore Purchase

    private var restorePurchaseButton: some View {
        Button {
            Task { await store.restorePurchases() }
        } label: {
            Text("Restore Purchase")
                .font(MatchaTokens.Typography.footnote)
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .underline()
        }
        .disabled(store.isLoading)
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
            .font(.system(size: 10))
            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, MatchaTokens.Spacing.medium)
    }
}

// MARK: - Preview

#Preview("Swipes Exhausted") {
    PaywallView(.swipesExhausted)
        .preferredColorScheme(.dark)
}

#Preview("Blurred Likes") {
    PaywallView(.blurredLikes)
        .preferredColorScheme(.dark)
}

#Preview("General") {
    PaywallView(.general)
        .preferredColorScheme(.dark)
}
