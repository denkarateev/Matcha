import SwiftUI
import PhotosUI

// MARK: - CreateOfferView

struct CreateOfferView: View {
    @Environment(\.dismiss) private var dismiss
    var repository: any MatchaRepository = APIMatchaRepository()

    // Form state
    @State private var title: String = ""
    @State private var offerType: CollaborationType = .barter
    @State private var bloggerReceives: String = ""
    @State private var businessReceives: String = ""
    @State private var slots: Int = 1
    @State private var unlimitedSlots: Bool = false
    @State private var hasExpiry: Bool = false
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    @State private var selectedNiches: Set<String> = []
    @State private var audienceTier: AudienceTier = .any
    @State private var guests: GuestsOption = .solo
    @State private var specialConditions: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoImage: Image? = nil

    // UI
    @State private var showPublishAlert = false
    @State private var isPublishing = false
    @State private var publishError: String = ""
    @State private var showPublishError = false

    let offerCredits: Int = 2

    private let allNiches = [
        "Food", "Travel", "Lifestyle", "Fashion", "Beauty",
        "Fitness", "Tech", "Music", "Art", "Photography",
        "Business", "Health", "Gaming", "Cooking", "Sports",
    ]

    private var canPublish: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !bloggerReceives.trimmingCharacters(in: .whitespaces).isEmpty
            && !businessReceives.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MatchaTokens.Spacing.large) {
                    creditsBar
                    photoSection
                    titleSection
                    typeSection
                    exchangeSection
                    slotsSection
                    expirySection
                    nichesSection
                    audienceSection
                    guestsSection
                    specialConditionsSection
                }
                .padding(.horizontal, MatchaTokens.Spacing.large)
                .padding(.top, MatchaTokens.Spacing.medium)
                .padding(.bottom, 120)
            }
            .background { MatchaTokens.backgroundGradient.ignoresSafeArea() }
            .navigationTitle("New Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                }
            }
            .overlay(alignment: .bottom) { publishBar }
        }
    }

    // MARK: - Credits Bar

    private var creditsBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.circle.fill")
                .font(.body)
                .foregroundStyle(MatchaTokens.Colors.accent)

            Text("\(offerCredits) offer credits remaining")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textPrimary)

            Spacer()

            Text("Get more")
                .font(.caption.weight(.bold))
                .foregroundStyle(MatchaTokens.Colors.background)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(MatchaTokens.Colors.accent, in: Capsule())
        }
        .padding(.horizontal, MatchaTokens.Spacing.medium)
        .padding(.vertical, 14)
        .liquidGlass(cornerRadius: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Photo

    private var photoSection: some View {
        formCard(title: "Offer Photo") {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    if let photoImage {
                        photoImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(MatchaTokens.Colors.elevated)
                            .frame(height: 160)
                            .overlay {
                                VStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(MatchaTokens.Colors.accent.opacity(0.6))
                                    Text("Add cover photo")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(MatchaTokens.Colors.textSecondary)
                                    Text("Defaults to your business photo")
                                        .font(.caption)
                                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                                }
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            photoImage != nil ? MatchaTokens.Colors.accent.opacity(0.3) : MatchaTokens.Colors.outline,
                            lineWidth: 1,
                            antialiased: true
                        )
                )
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photoImage = Image(uiImage: uiImage)
                    }
                }
            }

            if photoImage != nil {
                Button(action: { photoImage = nil; selectedPhoto = nil }) {
                    Label("Remove photo", systemImage: "xmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(MatchaTokens.Colors.danger)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        formCard(title: "Offer Title") {
            VStack(alignment: .leading, spacing: 6) {
                TextField("e.g. \"Free dinner for an Instagram Story\"", text: $title, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .onChange(of: title) { _, v in
                        if v.count > 60 { title = String(v.prefix(60)) }
                    }

                HStack {
                    if title.isEmpty {
                        Text("Required")
                            .font(.caption)
                            .foregroundStyle(MatchaTokens.Colors.danger.opacity(0.7))
                    }
                    Spacer()
                    Text("\(title.count)/60")
                        .font(.caption)
                        .foregroundStyle(title.count > 50 ? MatchaTokens.Colors.warning : MatchaTokens.Colors.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        title.isEmpty ? MatchaTokens.Colors.danger.opacity(0.4) : MatchaTokens.Colors.outline,
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Type Toggle

    private var typeSection: some View {
        formCard(title: "Collaboration Type") {
            HStack(spacing: 0) {
                ForEach([CollaborationType.barter, .paid], id: \.self) { type in
                    let selected = offerType == type
                    Button(action: {
                        withAnimation(MatchaTokens.Animations.buttonPress) { offerType = type }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: typeIcon(type))
                                .font(.body)
                            Text(type.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(selected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selected ? typeColor(type) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(4)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func typeIcon(_ type: CollaborationType) -> String {
        switch type {
        case .barter: "arrow.trianglehead.2.counterclockwise.rotate.90"
        case .paid: "dollarsign.circle.fill"
        case .both: "arrow.trianglehead.2.counterclockwise.rotate.90"
        }
    }

    private func typeColor(_ type: CollaborationType) -> Color {
        switch type {
        case .barter: MatchaTokens.Colors.accent
        case .paid: MatchaTokens.Colors.success
        case .both: MatchaTokens.Colors.accent
        }
    }

    // MARK: - Exchange Section

    private var exchangeSection: some View {
        VStack(spacing: MatchaTokens.Spacing.medium) {
            formCard(title: "Blogger Receives") {
                exchangeField(
                    text: $bloggerReceives,
                    placeholder: "e.g. Free stay, dinner for two, product sample...",
                    icon: "person.fill",
                    color: Color(hex: 0x7EB2FF)
                )
            }

            formCard(title: "Business Receives") {
                exchangeField(
                    text: $businessReceives,
                    placeholder: "e.g. 1 Instagram Story + 1 Reel, review on Google...",
                    icon: "building.2.fill",
                    color: MatchaTokens.Colors.accent
                )
            }
        }
    }

    private func exchangeField(text: Binding<String>, placeholder: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .padding(.top, 2)

                TextField(placeholder, text: text, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(3, reservesSpace: false)
                    .onChange(of: text.wrappedValue) { _, v in
                        if v.count > 200 { text.wrappedValue = String(v.prefix(200)) }
                    }
            }

            HStack {
                if text.wrappedValue.isEmpty {
                    Text("Required")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.danger.opacity(0.7))
                }
                Spacer()
                Text("\(text.wrappedValue.count)/200")
                    .font(.caption)
                    .foregroundStyle(
                        text.wrappedValue.count > 180
                            ? MatchaTokens.Colors.warning
                            : MatchaTokens.Colors.textSecondary.opacity(0.5)
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    text.wrappedValue.isEmpty ? MatchaTokens.Colors.danger.opacity(0.4) : MatchaTokens.Colors.outline,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Slots

    private var slotsSection: some View {
        formCard(title: "Number of Slots") {
            VStack(spacing: MatchaTokens.Spacing.medium) {
                // No Limit toggle
                Toggle(isOn: $unlimitedSlots) {
                    HStack(spacing: 10) {
                        Image(systemName: "infinity")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(unlimitedSlots ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Limit")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                            Text("Any number of bloggers can join")
                                .font(.caption)
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        }
                    }
                }
                .tint(MatchaTokens.Colors.accent)
                .onChange(of: unlimitedSlots) { _, isOn in
                    if !isOn && slots < 1 { slots = 1 }
                }

                if !unlimitedSlots {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(slots)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                            Text(slots == 1 ? "blogger slot" : "blogger slots")
                                .font(.caption)
                                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        }

                        Spacer()

                        HStack(spacing: 0) {
                            Button(action: { if slots > 1 { withAnimation(.spring(response: 0.25)) { slots -= 1 } } }) {
                                Image(systemName: "minus")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(slots > 1 ? MatchaTokens.Colors.textPrimary : MatchaTokens.Colors.textSecondary.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .background(MatchaTokens.Colors.elevated)
                            }
                            .disabled(slots <= 1)

                            Text("\(slots)")
                                .font(.headline)
                                .foregroundStyle(MatchaTokens.Colors.textPrimary)
                                .frame(width: 48, height: 44)
                                .background(MatchaTokens.Colors.surface)

                            Button(action: { if slots < 10 { withAnimation(.spring(response: 0.25)) { slots += 1 } } }) {
                                Image(systemName: "plus")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(slots < 10 ? MatchaTokens.Colors.accent : MatchaTokens.Colors.textSecondary.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .background(MatchaTokens.Colors.elevated)
                            }
                            .disabled(slots >= 10)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(MatchaTokens.Animations.cardAppear, value: unlimitedSlots)
        }
    }

    // MARK: - Expiry

    private var expirySection: some View {
        formCard(title: "Expiry") {
            VStack(spacing: MatchaTokens.Spacing.medium) {
                Toggle(isOn: $hasExpiry) {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.warning)
                        Text("Set expiry date")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    }
                }
                .tint(MatchaTokens.Colors.accent)

                if hasExpiry {
                    DatePicker(
                        "Expires on",
                        selection: $expiryDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .tint(MatchaTokens.Colors.accent)
                    .colorScheme(.dark)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "infinity")
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                        Text("No expiry limit")
                            .font(.subheadline)
                            .foregroundStyle(MatchaTokens.Colors.textSecondary)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Niches

    private var nichesSection: some View {
        formCard(title: "Preferred Blogger Niche") {
            VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
                HStack {
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    Spacer()
                    if !selectedNiches.isEmpty {
                        Text("\(selectedNiches.count) selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                    }
                }

                NicheFlowLayout(spacing: 8) {
                    ForEach(allNiches, id: \.self) { niche in
                        let isSelected = selectedNiches.contains(niche)
                        Button(action: {
                            withAnimation(MatchaTokens.Animations.buttonPress) {
                                if isSelected {
                                    selectedNiches.remove(niche)
                                } else {
                                    selectedNiches.insert(niche)
                                }
                            }
                        }) {
                            HStack(spacing: 5) {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                }
                                Text(niche)
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(isSelected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                isSelected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color.clear : MatchaTokens.Colors.outline,
                                    lineWidth: 1
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Audience Tier

    private var audienceSection: some View {
        formCard(title: "Min Audience Size") {
            VStack(spacing: 8) {
                ForEach(AudienceTier.allCases) { tier in
                    let selected = audienceTier == tier
                    Button(action: {
                        withAnimation(MatchaTokens.Animations.buttonPress) { audienceTier = tier }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .strokeBorder(
                                        selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.outline,
                                        lineWidth: selected ? 0 : 1.5
                                    )
                                    .frame(width: 20, height: 20)
                                if selected {
                                    Circle()
                                        .fill(MatchaTokens.Colors.accent)
                                        .frame(width: 20, height: 20)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(MatchaTokens.Colors.background)
                                }
                            }

                            Text(tier.label)
                                .font(.subheadline.weight(selected ? .semibold : .regular))
                                .foregroundStyle(selected ? MatchaTokens.Colors.textPrimary : MatchaTokens.Colors.textSecondary)

                            Spacer()
                        }
                        .padding(.horizontal, MatchaTokens.Spacing.medium)
                        .padding(.vertical, 12)
                        .background(
                            selected ? MatchaTokens.Colors.accent.opacity(0.08) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Guests

    private var guestsSection: some View {
        formCard(title: "Guests") {
            HStack(spacing: 8) {
                ForEach(GuestsOption.allCases) { option in
                    let selected = guests == option
                    Button(action: {
                        withAnimation(MatchaTokens.Animations.buttonPress) { guests = option }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: option == .solo ? "person.fill" : "person.2.fill")
                                .font(.subheadline)
                            Text(option.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(selected ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selected ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Special Conditions

    private var specialConditionsSection: some View {
        formCard(title: "Special Conditions") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(MatchaTokens.Colors.warning.opacity(0.7))
                        .padding(.top, 2)

                    TextField(
                        "Optional: e.g. must tag @business, no competitor brands...",
                        text: $specialConditions,
                        axis: .vertical
                    )
                    .font(.subheadline)
                    .foregroundStyle(MatchaTokens.Colors.textPrimary)
                    .lineLimit(4, reservesSpace: false)
                }

                HStack {
                    Text("Optional")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.5))
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(MatchaTokens.Colors.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(MatchaTokens.Colors.outline, lineWidth: 1)
            )
        }
    }

    // MARK: - Publish Bar

    private var publishBar: some View {
        VStack(spacing: 0) {
            Divider().background(MatchaTokens.Colors.outline)

            VStack(spacing: 6) {
                Button(action: {
                    if canPublish { showPublishAlert = true }
                }) {
                    HStack(spacing: 10) {
                        if isPublishing {
                            ProgressView()
                                .tint(MatchaTokens.Colors.background)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.body.weight(.semibold))
                        }
                        Text("Publish Offer")
                            .font(.headline)
                    }
                    .foregroundStyle(canPublish ? MatchaTokens.Colors.background : MatchaTokens.Colors.textSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        canPublish ? MatchaTokens.Colors.accent : MatchaTokens.Colors.elevated,
                        in: RoundedRectangle(cornerRadius: MatchaTokens.Radius.button, style: .continuous)
                    )
                }
                .disabled(!canPublish || isPublishing)

                if !canPublish {
                    Text("Fill in title and exchange details to publish")
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                        Text("This will use 1 Offer Credit")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(MatchaTokens.Colors.textSecondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, MatchaTokens.Spacing.large)
            .padding(.vertical, MatchaTokens.Spacing.medium)
            .background(MatchaTokens.Colors.background)
        }
        .alert("Publish Offer?", isPresented: $showPublishAlert) {
            Button("Publish", role: .none) {
                isPublishing = true
                Task {
                    do {
                        let request = OfferCreateRequest(
                            title: title.trimmingCharacters(in: .whitespaces),
                            type: offerType,
                            bloggerReceives: bloggerReceives.trimmingCharacters(in: .whitespaces),
                            businessReceives: businessReceives.trimmingCharacters(in: .whitespaces),
                            slotsTotal: unlimitedSlots ? 0 : slots,
                            photoURL: "https://images.unsplash.com/photo-1540541338287-41700207dee6?w=600",
                            expiresAt: hasExpiry ? expiryDate : nil,
                            preferredBloggerNiche: selectedNiches.first,
                            minAudience: audienceTier == .any ? nil : audienceTier.label,
                            guests: guests == .solo ? nil : guests.rawValue,
                            specialConditions: specialConditions.isEmpty ? nil : specialConditions,
                            isLastMinute: false
                        )
                        _ = try await repository.createOffer(request)
                        MatchaHaptic.success()
                        isPublishing = false
                        dismiss()
                    } catch {
                        isPublishing = false
                        publishError = error.localizedDescription
                        showPublishError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will use 1 offer credit. You have \(offerCredits) credit\(offerCredits == 1 ? "" : "s") remaining.")
        }
        .alert("Failed to Publish", isPresented: $showPublishError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(publishError)
        }
    }

    // MARK: - Helpers

    private func formCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MatchaTokens.Spacing.medium) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(MatchaTokens.Colors.textSecondary)
                .tracking(1.2)
            content()
        }
    }
}

// MARK: - NicheFlowLayout

private struct NicheFlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxY: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + rowHeight)
        }
        return CGSize(width: width, height: maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    CreateOfferView()
        .preferredColorScheme(.dark)
}
