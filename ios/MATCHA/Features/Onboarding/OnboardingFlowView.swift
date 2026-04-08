import Observation
import PhotosUI
import SwiftUI

// MARK: - OnboardingFlowView

struct OnboardingFlowView: View {
    @State private var store: OnboardingStore

    init(appState: AppState) {
        _store = State(initialValue: OnboardingStore(appState: appState))
    }

    var body: some View {
        ZStack {
            Color(hex: 0x050505).ignoresSafeArea()

            switch store.step {
            case 0:
                WelcomeScreen(store: store)
                    .transition(.opacity)
            case 1:
                RegistrationScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 2:
                MiniProfileScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            default:
                CategoryScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.step)
    }
}

// MARK: - Screen 1: Welcome + Role Selection (Light theme)

private struct WelcomeScreen: View {
    @Bindable var store: OnboardingStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Color.clear.frame(width: 36, height: 36)
                Spacer()
                VStack(spacing: 4) {
                    Text("Welcome !")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Sign up as")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Blogger section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Blogger")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.leading, 4)

                        roleCard(
                            icon: "person.crop.rectangle.stack",
                            title: "Content Creator",
                            subtitle: "You create content on social media",
                            role: .blogger
                        )
                    }

                    // Business section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Business")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.leading, 4)

                        roleCard(
                            icon: "storefront",
                            title: "Venue",
                            subtitle: "You are the representative of a business",
                            role: .business
                        )
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
            }

            // Bottom buttons
            VStack(spacing: 12) {
                Button {
                    store.switchAuthMode(to: false)
                    withAnimation { store.step = 1 }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    store.switchAuthMode(to: true)
                    withAnimation { store.step = 1 }
                } label: {
                    Text("I already have an account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 2)

                // Pro teaser
                HStack(spacing: 10) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MatchaTokens.Colors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("MATCHA Pro")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text("SuperSwipes, unlimited matches, priority feed")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Text("Learn more")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MatchaTokens.Colors.accent)
                }
                .padding(12)
                .background(MatchaTokens.Colors.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 0.5)
                )
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func roleCard(icon: String, title: String, subtitle: String, role: Role) -> some View {
        let selected = store.selectedRole == role
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                store.selectedRole = role
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(selected ? MatchaTokens.Colors.accent : .white.opacity(0.5))
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? MatchaTokens.Colors.accent.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        selected ? MatchaTokens.Colors.accent : Color.white.opacity(0.12),
                        lineWidth: selected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 2: Registration + Role

private struct RegistrationScreen: View {
    @Bindable var store: OnboardingStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button {
                        withAnimation { store.step = 0 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text(store.isLoginMode ? "Log In" : "Create Account")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                // Progress (signup only)
                if !store.isLoginMode {
                    progressBar(step: 1, total: store.totalSteps)
                }

                // Mode toggle
                if !store.isLoginMode {
                    modeToggle
                }

                // Fields
                VStack(spacing: 14) {
                    MatchaTextField(
                        icon: "envelope",
                        placeholder: "Email address",
                        text: $store.email,
                        fieldState: store.emailFieldState,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        contentType: .emailAddress
                    )

                    MatchaSecureField(
                        placeholder: store.isLoginMode ? "Password" : "Password (min 8 chars)",
                        text: $store.password,
                        fieldState: store.passwordFieldState,
                        contentType: store.isLoginMode ? .password : .newPassword
                    )
                }

                // Role toggle (signup only)
                if !store.isLoginMode {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I am a")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))

                        HStack(spacing: 0) {
                            roleTab("Blogger", role: .blogger)
                            roleTab("Business", role: .business)
                        }
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                // Error
                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }

                // Submit
                Button {
                    Task { await store.advanceFromRegistration() }
                } label: {
                    ZStack {
                        Text(store.isLoginMode ? "Log In" : "Continue")
                            .opacity(store.isLoading ? 0 : 1)
                        if store.isLoading {
                            ProgressView().tint(.black)
                        }
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(store.isLoading)
                .accessibilityLabel(store.isLoginMode ? "Log in to MATCHA" : "Continue to next step")

                // Switch mode link
                Button {
                    withAnimation {
                        store.switchAuthMode(to: !store.isLoginMode)
                    }
                } label: {
                    Text(store.isLoginMode ? "Don't have an account? Sign up" : "Already have an account? Log in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var modeToggle: some View {
        EmptyView() // Mode switch is via the bottom link now
    }

    private func roleTab(_ title: String, role: Role) -> some View {
        let selected = store.selectedRole == role
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                store.selectedRole = role
            }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selected ? .black : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    selected ? MatchaTokens.Colors.accent : .clear,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
        }
        .padding(2)
    }
}

// MARK: - Screen 3: Mini Profile

private struct MiniProfileScreen: View {
    @Bindable var store: OnboardingStore
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button {
                        withAnimation { store.step = 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text("Your Profile")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                progressBar(step: 2, total: store.totalSteps)

                // Photo + Name
                HStack(alignment: .top, spacing: 16) {
                    photoTile
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add a photo and name")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        MatchaTextField(
                            icon: "person",
                            placeholder: "Display name",
                            text: $store.name,
                            fieldState: store.nameFieldState,
                            autocorrectionDisabled: true,
                            contentType: .name
                        )
                    }
                }

                // Error
                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }

                // Submit
                Button {
                    Task { await store.submitProfile() }
                } label: {
                    ZStack {
                        Text(store.isLoading ? "" : (store.selectedRole == .business ? "Continue" : "Get Started"))
                            .opacity(store.isLoading ? 0 : 1)
                        if store.isLoading {
                            ProgressView().tint(.black)
                        }
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(store.isLoading)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onChange(of: photoPickerItem) { _, newItem in
            Task { await store.loadPickedPhoto(newItem) }
        }
    }

    private var photoTile: some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                store.pickedPhoto == nil
                                    ? Color.white.opacity(0.15)
                                    : MatchaTokens.Colors.accent.opacity(0.5),
                                style: StrokeStyle(lineWidth: 1.5, dash: store.pickedPhoto == nil ? [6, 4] : [])
                            )
                    )

                if let photo = store.pickedPhoto {
                    photo
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 125)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                        Text("Photo")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .frame(width: 100, height: 125)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 4: Category (Business only)

private struct CategoryScreen: View {
    @Bindable var store: OnboardingStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button {
                        withAnimation { store.step = 2 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text("Your Category")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                progressBar(step: 3, total: 3)

                // Title + Subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's your business?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)

                    Text("This helps bloggers find relevant collabs")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Category grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(BusinessCategory.allCases) { category in
                        CategoryChip(
                            title: category.title,
                            isSelected: store.selectedCategory == category
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.selectedCategory = category
                            }
                        }
                    }
                }

                // Error
                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }

                // Submit
                Button {
                    Task { await store.submitCategory() }
                } label: {
                    ZStack {
                        Text(store.isLoading ? "" : "Get Started")
                            .opacity(store.isLoading ? 0 : 1)
                        if store.isLoading {
                            ProgressView().tint(.black)
                        }
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(store.isLoading)

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Shared Components

private func progressBar(step: Int, total: Int) -> some View {
    HStack(spacing: 6) {
        ForEach(1...total, id: \.self) { i in
            Capsule()
                .fill(i <= step ? MatchaTokens.Colors.accent : Color.white.opacity(0.1))
                .frame(height: 3)
        }
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(MatchaTokens.Colors.danger)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            MatchaTokens.Colors.danger.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? MatchaTokens.Colors.accent : Color.white.opacity(0.06),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
    }
}

// MARK: - OnboardingStore

@MainActor
@Observable
final class OnboardingStore {
    private struct PhotoUploadResponse: Decodable {
        let url: String
    }

    private let appState: AppState

    var step: Int = 0
    var email: String = ""
    var password: String = ""
    var isLoginMode: Bool = false
    var selectedRole: Role = .blogger

    var name: String = ""
    var selectedCategory: BusinessCategory = .restaurantCafe
    var pickedPhoto: Image?
    var pickedPhotoData: Data?

    var isLoading: Bool = false
    var errorMessage: String?

    var emailFieldState: MatchaFieldState = .normal
    var passwordFieldState: MatchaFieldState = .normal
    var nameFieldState: MatchaFieldState = .normal

    var totalSteps: Int {
        selectedRole == .business ? 3 : 2
    }

    init(appState: AppState) {
        self.appState = appState
    }

    func switchAuthMode(to isLoginMode: Bool) {
        guard self.isLoginMode != isLoginMode else { return }
        self.isLoginMode = isLoginMode
        errorMessage = nil
        emailFieldState = .normal
        passwordFieldState = .normal
        nameFieldState = .normal
    }

    func advanceFromRegistration() async {
        errorMessage = nil
        emailFieldState = .normal
        passwordFieldState = .normal

        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty else {
            emailFieldState = .error("Email is required")
            errorMessage = "Please enter your email address."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            emailFieldState = .error("Enter a valid email address")
            errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 8 else {
            passwordFieldState = .error("Minimum 8 characters")
            errorMessage = "Password must be at least 8 characters."
            return
        }

        emailFieldState = .success
        passwordFieldState = .success

        if isLoginMode {
            isLoading = true
            defer { isLoading = false }

            do {
                let response = try await AuthService.shared.login(
                    email: trimmedEmail,
                    password: password
                )
                appState.completeAuthOnboarding(authResponse: response)
                await appState.loadCurrentUser()
            } catch let networkError as NetworkError {
                errorMessage = networkError.errorDescription ?? "Could not log in. Please try again."
            } catch {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
            }
            return
        }

        withAnimation { step = 2 }
    }

    func submitProfile() async {
        errorMessage = nil
        nameFieldState = .normal

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            nameFieldState = .error("Display name is required")
            errorMessage = "Please enter your display name."
            return
        }

        guard trimmedName.count <= 50 else {
            nameFieldState = .error("Name must be 50 characters or fewer")
            errorMessage = "Name must be 50 characters or fewer."
            return
        }

        guard pickedPhoto != nil else {
            errorMessage = "Please add a profile photo (required)."
            return
        }

        nameFieldState = .success

        // Business users go to category selection first
        if selectedRole == .business {
            withAnimation { step = 3 }
            return
        }

        // Blogger — register immediately
        await performRegistration()
    }

    func submitCategory() async {
        errorMessage = nil
        await performRegistration()
    }

    private func performRegistration() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: AuthResponse
            let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                guard let pickedPhotoData else {
                    throw NetworkError.domainError(
                        code: "missing_photo",
                        message: "Please add a profile photo before creating your account."
                    )
                }
                let upload: PhotoUploadResponse = try await NetworkService.shared.upload(
                    path: "/auth/upload-photo",
                    imageData: pickedPhotoData,
                    filename: "profile-photo.jpg"
                )
                response = try await AuthService.shared.register(
                    email: trimmedEmail,
                    password: password,
                    role: selectedRole,
                    fullName: trimmedName,
                    primaryPhotoUrl: upload.url,
                    category: selectedRole == .business ? selectedCategory.rawValue : nil
                )
            } catch {
                let errMsg = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                if errMsg.lowercased().contains("already registered") || errMsg.lowercased().contains("conflict") {
                    response = try await AuthService.shared.login(
                        email: trimmedEmail,
                        password: password
                    )
                } else {
                    throw error
                }
            }

            appState.completeAuthOnboarding(authResponse: response)
            await appState.loadCurrentUser()

        } catch let networkError as NetworkError {
            errorMessage = networkError.errorDescription ?? "Something went wrong. Please try again."
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }

    func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                pickedPhoto = Image(uiImage: uiImage)
                pickedPhotoData = uiImage.jpegData(compressionQuality: 0.86) ?? data
            }
        } catch {
            errorMessage = "Could not load the selected photo. Please try again."
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Previews

#Preview("Welcome") {
    OnboardingFlowView(appState: AppState())
}
