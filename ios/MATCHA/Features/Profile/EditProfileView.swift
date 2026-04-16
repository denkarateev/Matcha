import PhotosUI
import SwiftUI

// MARK: - EditProfileView (Bumble-style)

struct EditProfileView: View {
    let profile: UserProfile
    let repository: any MatchaRepository
    var onSaved: (UserProfile) -> Void

    // Form state
    @State private var name: String
    @State private var bio: String
    @State private var district: String
    @State private var instagramHandle: String
    @State private var tiktokHandle: String
    @State private var selectedNiches: Set<String>
    @State private var collaborationType: CollaborationType
    @State private var languageInput: String = ""
    @State private var languages: [String]
    @State private var photoSlots: [PhotoSlot] = []

    // UI state
    @State private var selectedTab: EditTab = .edit
    @State private var previewPhotoIndex: Int = 0
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showDiscardAlert = false
    @FocusState private var focusedField: EditField?
    @Environment(\.dismiss) private var dismiss

    // Change detection
    @State private var initialName: String = ""
    @State private var initialBio: String = ""
    @State private var initialDistrict: String = ""
    @State private var initialNiches: Set<String> = []
    @State private var initialCollaborationType: CollaborationType = .both
    @State private var initialLanguages: [String] = []
    @State private var initialPhotoCount: Int = 0
    @State private var initialInstagramHandle: String = ""
    @State private var initialTiktokHandle: String = ""

    private var hasChanges: Bool {
        name != initialName ||
        bio != initialBio ||
        district != initialDistrict ||
        instagramHandle != initialInstagramHandle ||
        tiktokHandle != initialTiktokHandle ||
        selectedNiches != initialNiches ||
        collaborationType != initialCollaborationType ||
        languages != initialLanguages ||
        photoSlots.count != initialPhotoCount
    }

    private enum EditTab: String, CaseIterable {
        case edit = "Edit"
        case preview = "Preview"
    }

    private enum EditField: Hashable {
        case name, bio, district, language, instagram, tiktok
    }

    private let allNiches = [
        "Food & Drink", "Travel", "Wellness & Fitness",
        "Beauty & Fashion", "Lifestyle", "Family & Kids",
        "Pets", "Art & Design", "Business & Tech",
        "Eco & Sustainable", "Events & Nightlife",
    ]

    private let allDistricts = FeedFilterView.baliDistricts

    private let allLanguages = [
        "English", "Russian", "Indonesian", "French", "German",
        "Spanish", "Italian", "Portuguese", "Japanese", "Korean",
        "Chinese", "Arabic", "Hindi", "Dutch", "Swedish",
        "Thai", "Vietnamese", "Turkish", "Polish", "Ukrainian",
    ]

    // MARK: - Completion score

    private var completionPercent: Int {
        var score = 0
        if !photoSlots.isEmpty { score += 25 }
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { score += 10 }
        if !bio.trimmingCharacters(in: .whitespaces).isEmpty { score += 20 }
        if !selectedNiches.isEmpty { score += 20 }
        if !languages.isEmpty { score += 10 }
        if !district.trimmingCharacters(in: .whitespaces).isEmpty { score += 5 }
        if !instagramHandle.trimmingCharacters(in: .whitespaces).isEmpty { score += 10 }
        return min(score, 100)
    }

    init(
        profile: UserProfile,
        repository: any MatchaRepository,
        onSaved: @escaping (UserProfile) -> Void
    ) {
        self.profile = profile
        self.repository = repository
        self.onSaved = onSaved
        _name = State(initialValue: profile.name)
        _bio = State(initialValue: profile.bio)
        _district = State(initialValue: profile.district ?? profile.locationDistrict ?? "")
        _instagramHandle = State(initialValue: profile.instagramHandle ?? "")
        _tiktokHandle = State(initialValue: profile.tiktokHandle ?? "")
        _selectedNiches = State(initialValue: Set(profile.niches))
        _collaborationType = State(initialValue: profile.collaborationType)
        _languages = State(initialValue: profile.languages)
        // Load existing photos as remote-URL slots
        _photoSlots = State(initialValue: profile.photoURLs.map { PhotoSlot(remoteURL: $0) })
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Edit / Preview segment
                segmentTabs

                if selectedTab == .edit {
                    editContent
                } else {
                    previewContent
                }
            }
            .background(MatchaTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Edit Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(MatchaTokens.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveAndDismiss) {
                        if isSaving {
                            ProgressView().tint(MatchaTokens.Colors.accent).scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1), in: Circle())
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(hasChanges)
            .alert("Discard changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .onAppear {
                initialName = name
                initialBio = bio
                initialDistrict = district
                initialInstagramHandle = instagramHandle
                initialTiktokHandle = tiktokHandle
                initialNiches = selectedNiches
                initialCollaborationType = collaborationType
                initialLanguages = languages
                initialPhotoCount = photoSlots.count
            }
        }
    }

    // MARK: - Segment Tabs

    private var segmentTabs: some View {
        HStack(spacing: 0) {
            ForEach(EditTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? MatchaTokens.Colors.accent : .white.opacity(0.5))

                        Rectangle()
                            .fill(selectedTab == tab ? MatchaTokens.Colors.accent : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .background {
            VStack {
                Spacer()
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            }
        }
    }

    // MARK: - Edit Content

    private var editContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Profile completion bar
                completionBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                // Photos
                editSection(title: "PHOTOS", bonus: photoSlots.isEmpty ? nil : "+25%") {
                    PhotoGridView(photos: $photoSlots)
                }

                // Name
                editSection(title: "NAME", important: true) {
                    editTextField("Your display name", text: $name, maxLength: 20, focused: .name)
                }

                // About Me
                editSection(title: "ABOUT ME", important: true, bonus: bio.isEmpty ? nil : "+20%") {
                    VStack(alignment: .trailing, spacing: 8) {
                        editTextEditor("Tell brands about yourself...", text: $bio, focused: .bio)
                        Text("\(bio.count)/150")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                // Niches
                editSection(title: "NICHES", bonus: selectedNiches.isEmpty ? nil : "+20%") {
                    nichesGrid
                }

                // Collab Type
                editSection(title: "COLLAB TYPE") {
                    collabPicker
                }

                // Languages — picker chips
                editSection(title: "LANGUAGES") {
                    languagesPicker
                }

                // District — picker
                editSection(title: "DISTRICT") {
                    districtPicker
                }

                // Instagram
                editSection(title: "INSTAGRAM", bonus: instagramHandle.isEmpty ? nil : "+10%") {
                    editTextField("@yourusername", text: $instagramHandle, focused: .instagram)
                }

                // TikTok
                editSection(title: "TIKTOK") {
                    editTextField("@yourusername", text: $tiktokHandle, focused: .tiktok)
                }

                // Portfolio Wall
                editSection(title: "PORTFOLIO WALL") {
                    portfolioWallPlaceholder
                }

                // Error
                if let saveError {
                    Text(saveError)
                        .font(.caption)
                        .foregroundStyle(MatchaTokens.Colors.danger)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                Color.clear.frame(height: 60)
            }
        }
    }

    // MARK: - Preview Content

    private var previewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Preview card (simulates how others see you)
                previewCard
                    .padding(20)

                Text("This is how other users see your profile")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 40)
            }
        }
    }

    private var previewCard: some View {
        let allPhotos = photoSlots.compactMap { slot -> AnyView? in
            if let img = slot.image {
                return AnyView(Image(uiImage: img).resizable().aspectRatio(contentMode: .fill))
            } else if let url = slot.remoteURL {
                return AnyView(
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .overlay { ProgressView().tint(.white.opacity(0.3)) }
                        }
                    }
                )
            }
            return nil
        }

        return VStack(spacing: 0) {
            // Photo carousel
            ZStack(alignment: .bottom) {
                if allPhotos.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 420)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.white.opacity(0.15))
                        }
                } else {
                    TabView(selection: $previewPhotoIndex) {
                        ForEach(Array(allPhotos.enumerated()), id: \.offset) { index, view in
                            view
                                .frame(height: 420)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 420)
                }

                // Page indicator — segmented bars + counter (same as match card)
                if allPhotos.count > 1 {
                    VStack {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                ForEach(0..<allPhotos.count, id: \.self) { index in
                                    Capsule()
                                        .fill(index == previewPhotoIndex ? Color.white : Color.white.opacity(0.35))
                                        .frame(height: 3)
                                        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                                        .animation(.easeInOut(duration: 0.2), value: previewPhotoIndex)
                                }
                            }
                            .padding(.horizontal, 12)

                            HStack(spacing: 5) {
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("\(previewPhotoIndex + 1)/\(allPhotos.count)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.45), in: Capsule())
                            .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                        }
                        .padding(.top, 12)

                        Spacer()
                    }
                    .frame(height: 420)
                }

                // Gradient + info
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.4),
                        .init(color: .black.opacity(0.8), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(MatchaTokens.Colors.accent)
                        }
                    }

                    HStack(spacing: 6) {
                        if let cat = profile.category {
                            Text(cat.title)
                        } else {
                            Text("Influencer")
                        }
                        Text("·")
                        Text(district.isEmpty ? "Bali" : district)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                    if !selectedNiches.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(Array(selectedNiches).sorted().prefix(3), id: \.self) { niche in
                                Text(niche)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.white.opacity(0.15), in: Capsule())
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Bio preview
            if !bio.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func editSection<Content: View>(
        title: String,
        important: Bool = false,
        bonus: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                if important {
                    Circle()
                        .fill(MatchaTokens.Colors.danger)
                        .frame(width: 6, height: 6)
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(0.8)

                if important {
                    Text("IMPORTANT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MatchaTokens.Colors.danger, in: Capsule())
                }

                Spacer()

                if let bonus {
                    Text(bonus)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
            }

            // Content card
            content()
                .padding(16)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Completion Bar

    private var completionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Profile completeness")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("\(completionPercent)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(MatchaTokens.Colors.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    Capsule()
                        .fill(MatchaTokens.Colors.accent)
                        .frame(width: max(geo.size.width * Double(completionPercent) / 100, 8))
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Niches Grid

    private var nichesGrid: some View {
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
    }

    // MARK: - Collab Picker

    private var collabPicker: some View {
        HStack(spacing: 8) {
            ForEach([CollaborationType.barter, .paid, .both], id: \.self) { type in
                let selected = collaborationType == type
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        collaborationType = type
                    }
                } label: {
                    Text(type.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selected ? .black : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
            }
        }
    }

    // MARK: - District Picker

    private var districtPicker: some View {
        FlowLayout(spacing: 8) {
            ForEach(allDistricts, id: \.self) { name in
                let selected = district == name
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        district = selected ? "" : name
                    }
                } label: {
                    HStack(spacing: 5) {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selected ? .black : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.08),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            selected ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Languages Picker

    private var languagesPicker: some View {
        FlowLayout(spacing: 8) {
            ForEach(allLanguages, id: \.self) { lang in
                let selected = languages.contains(lang)
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        if selected {
                            languages.removeAll { $0 == lang }
                        } else {
                            languages.append(lang)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                        Text(lang)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selected ? .black : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.08),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            selected ? Color.clear : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Portfolio Wall Placeholder

    private var portfolioWallPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.2))

            Text("Showcase your best work")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))

            Text("Add past collabs to get 3x more matches")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    Color.white.opacity(0.15),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])
                )
        }
    }

    // MARK: - Text Fields

    private func editTextField(_ placeholder: String, text: Binding<String>, maxLength: Int? = nil, focused: EditField) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .focused($focusedField, equals: focused)
            .onChange(of: text.wrappedValue) { _, newValue in
                if let maxLength, newValue.count > maxLength {
                    text.wrappedValue = String(newValue.prefix(maxLength))
                }
            }
    }

    private func editTextEditor(_ placeholder: String, text: Binding<String>, focused: EditField) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.top, 1)
                    .allowsHitTesting(false)
            }

            TextEditor(text: text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 80, maxHeight: 140)
                .focused($focusedField, equals: focused)
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.count > 150 {
                        text.wrappedValue = String(newValue.prefix(150))
                    }
                }
        }
    }

    // MARK: - Actions

    private func addLanguage() {
        let trimmed = languageInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !languages.contains(trimmed) else { return }
        languages.append(trimmed)
        languageInput = ""
    }

    private struct PhotoUploadResponse: Decodable {
        let url: String
    }

    private func saveAndDismiss() {
        saveError = nil
        isSaving = true
        Task {
            do {
                // 1. Build full photo URL array preserving slot order
                // Each slot is either an existing remote URL or a new image to upload
                var allPhotoURLs: [String] = []
                for slot in photoSlots {
                    if let image = slot.image,
                       let data = image.jpegData(compressionQuality: 0.85) {
                        // New photo — upload
                        let upload: PhotoUploadResponse = try await NetworkService.shared.upload(
                            path: "/auth/upload-photo",
                            imageData: data,
                            filename: "profile-\(UUID().uuidString).jpg"
                        )
                        allPhotoURLs.append(upload.url)
                    } else if let remoteURL = slot.remoteURL?.absoluteString {
                        // Existing photo — keep URL
                        allPhotoURLs.append(remoteURL)
                    }
                }

                // 2. Build update request
                var update = ProfileUpdateRequest(
                    displayName: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    country: profile.countryCode,
                    instagramHandle: instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines),
                    tiktokHandle: tiktokHandle.trimmingCharacters(in: .whitespacesAndNewlines),
                    district: district.trimmingCharacters(in: .whitespacesAndNewlines),
                    niches: Array(selectedNiches).sorted(),
                    languages: languages,
                    bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
                    collabType: collaborationType.rawValue
                )

                // Always send full photo array — primary is always first slot
                if !allPhotoURLs.isEmpty {
                    update.photoUrls = allPhotoURLs
                    update.primaryPhotoUrl = allPhotoURLs.first
                }

                let updated = try await repository.updateProfile(update)
                let mapped = UserProfile.from(
                    profile: updated,
                    role: profile.role,
                    subscriptionPlan: profile.subscriptionPlan,
                    verificationLevel: profile.verificationLevel
                )
                await MainActor.run {
                    isSaving = false
                    onSaved(mapped)
                    dismiss()
                }
            } catch let networkError as NetworkError {
                await MainActor.run {
                    isSaving = false
                    saveError = networkError.errorDescription ?? "Couldn't save right now."
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                }
            }
        }
    }
}
