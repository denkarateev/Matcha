import MapKit
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
            MatchaTokens.Colors.background.ignoresSafeArea()

            switch store.step {
            case 0:
                OnboardingSlidesScreen(store: store)
                    .transition(.opacity)
            case 1:
                WelcomeScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 2:
                RegistrationScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 3:
                PersonalDetailsScreen(store: store)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case 4:
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

// MARK: - Screen 0: Onboarding Slides (InfluGold style)

private struct OnboardingSlidesScreen: View {
    @Bindable var store: OnboardingStore
    @State private var currentSlide = 0

    private let slides: [(image: String, title: String, subtitle: String)] = [
        (
            "https://images.unsplash.com/photo-1611042553484-d61f9d9bf757?w=800&h=1200&fit=crop",
            "Grow your brand\nwith real collabs",
            "Connect with top businesses in Bali for authentic partnerships"
        ),
        (
            "https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=800&h=1200&fit=crop",
            "Barter deals,\nno cash needed",
            "Exchange content for experiences — dinners, stays, events"
        ),
        (
            "https://images.unsplash.com/photo-1537953773345-d172ccf13cf1?w=800&h=1200&fit=crop",
            "Track every step\nof your collab",
            "From first match to published content — all in one place"
        ),
    ]

    var body: some View {
        ZStack {
            // Fullscreen image
            TabView(selection: $currentSlide) {
                ForEach(0..<slides.count, id: \.self) { index in
                    AsyncImage(url: URL(string: slides[index].image)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .ignoresSafeArea()
                        default:
                            LinearGradient(
                                colors: [
                                    MatchaTokens.Colors.accent.opacity(0.3),
                                    MatchaTokens.Colors.background
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .ignoresSafeArea()
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Skip button top-right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation { store.step = 1 }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(.black.opacity(0.3), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                Spacer()
            }

            // Bottom card
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentSlide ? MatchaTokens.Colors.accent : Color.gray.opacity(0.3))
                                .frame(width: i == currentSlide ? 24 : 8, height: 4)
                                .animation(.spring(response: 0.3), value: currentSlide)
                        }
                    }

                    // Title
                    Text(slides[currentSlide].title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .id(currentSlide) // force re-render for transition
                        .transition(.opacity)

                    // Subtitle
                    Text(slides[currentSlide].subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .id("sub-\(currentSlide)")
                        .transition(.opacity)

                    // CTA
                    Button {
                        if currentSlide < slides.count - 1 {
                            withAnimation(.spring(response: 0.35)) {
                                currentSlide += 1
                            }
                        } else {
                            withAnimation { store.step = 1 }
                        }
                    } label: {
                        Text(currentSlide < slides.count - 1 ? "Next" : "Get Started")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 40)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .fill(.white)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentSlide)
    }
}

// MARK: - Screen 1: Welcome + Role Selection

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
                    // Influencer section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Influencer")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.leading, 4)

                        roleCard(
                            icon: "person.crop.rectangle.stack",
                            title: "Influencer",
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
                    withAnimation { store.step = 2 }
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
                    withAnimation { store.step = 2 }
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

// MARK: - Screen 2: Registration + Role (onboarding style — white card)

private struct RegistrationScreen: View {
    @Bindable var store: OnboardingStore

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

                // Fields — dark style using existing MatchaTextField
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

                    if !store.isLoginMode {
                        MatchaSecureField(
                            placeholder: "Confirm Password",
                            text: $store.confirmPassword,
                            fieldState: store.password == store.confirmPassword || store.confirmPassword.isEmpty
                                ? .normal
                                : .error("Passwords don't match"),
                            contentType: .newPassword
                        )
                    }
                }

                // Terms (signup)
                if !store.isLoginMode {
                    Button {
                        withAnimation(.spring(response: 0.2)) { store.agreedToTerms.toggle() }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(store.agreedToTerms ? MatchaTokens.Colors.accent : .white.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 20, height: 20)
                                if store.agreedToTerms {
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(MatchaTokens.Colors.accent)
                                        .frame(width: 20, height: 20)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                            }
                            Text("I agree to the **Terms of Service** and **Privacy Policy**")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Error
                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }

                // Submit — accent button
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

                // Switch mode
                Button {
                    withAnimation { store.switchAuthMode(to: !store.isLoginMode) }
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

    private func darkRoleTab(_ title: String, role: Role) -> some View {
        let selected = store.selectedRole == role
        return Button {
            withAnimation(.spring(response: 0.25)) { store.selectedRole = role }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selected ? .black : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(selected ? MatchaTokens.Colors.accent : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(2)
    }

    // MARK: - Light text field (white card style)

    // Light helpers removed — using dark MatchaTextField/MatchaSecureField now

}

// MARK: - Screen 3: Personal Details

private struct PersonalDetailsScreen: View {
    @Bindable var store: OnboardingStore

    private let nationalities = [
        "Indonesian", "Russian", "Australian", "American", "British",
        "French", "German", "Dutch", "Japanese", "Korean",
        "Chinese", "Indian", "Brazilian", "Canadian", "Italian",
        "Spanish", "Thai", "Vietnamese", "Ukrainian", "Other",
    ]

    private let residences = [
        "Indonesia", "Russia", "Australia", "USA", "UK",
        "France", "Germany", "Netherlands", "Japan", "South Korea",
        "China", "India", "Brazil", "Canada", "Italy",
        "Spain", "Thailand", "Vietnam", "Ukraine", "Other",
    ]

    private let districts = [
        "Canggu", "Seminyak", "Kuta", "Ubud", "Uluwatu",
        "Nusa Dua", "Sanur", "Denpasar", "Jimbaran", "Kerobokan",
        "Berawa", "Pererenan", "Tabanan", "Gianyar", "Lovina",
        "Amed", "Nusa Penida", "Nusa Lembongan", "Other",
    ]

    private let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]

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
                    Text("About You")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                progressBar(step: 2, total: store.totalSteps)

                Text("Please fill in your details")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))

                // Nationality
                dropdownField(
                    icon: "globe",
                    placeholder: "Nationality",
                    selection: $store.selectedNationality,
                    options: nationalities
                )

                // Residence + District
                HStack(spacing: 12) {
                    dropdownField(
                        icon: "mappin",
                        placeholder: "Residence",
                        selection: $store.selectedResidence,
                        options: residences
                    )
                    dropdownField(
                        icon: "person.crop.rectangle",
                        placeholder: "I live in",
                        selection: $store.selectedDistrict,
                        options: districts
                    )
                }

                // Gender
                dropdownField(
                    icon: "person.2",
                    placeholder: "Gender",
                    selection: $store.selectedGender,
                    options: genders
                )

                // Birthday
                VStack(alignment: .leading, spacing: 8) {
                    Text("Birthday")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    HStack(spacing: 12) {
                        yearPicker
                        monthPicker
                        dayPicker
                    }
                }

                // Error
                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }

                // Continue
                Button {
                    store.advanceFromPersonalDetails()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(MatchaTokens.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Dropdown Field

    private func dropdownField(
        icon: String,
        placeholder: String,
        selection: Binding<String>,
        options: [String]
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) {
                    selection.wrappedValue = option
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(width: 20)

                Text(selection.wrappedValue.isEmpty ? placeholder : selection.wrappedValue)
                    .font(.system(size: 16))
                    .foregroundStyle(selection.wrappedValue.isEmpty ? .white.opacity(0.35) : .white)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Date Pickers

    private var yearPicker: some View {
        let currentYear = Calendar.current.component(.year, from: Date())
        let years = Array((currentYear - 80)...(currentYear - 13)).reversed()

        return Menu {
            ForEach(years, id: \.self) { year in
                // String(year) вместо "\(year)" — в RU locale Int-interp
                // вставляет thousand separator ("2 026" с non-breaking space).
                Button(String(year)) { store.birthYear = year }
            }
        } label: {
            pickerLabel(store.birthYear.map { String($0) } ?? "Year")
        }
    }

    private var monthPicker: some View {
        let months = Calendar.current.monthSymbols
        return Menu {
            ForEach(Array(months.enumerated()), id: \.offset) { index, name in
                Button(name) { store.birthMonth = index + 1 }
            }
        } label: {
            pickerLabel(store.birthMonth.map { Calendar.current.shortMonthSymbols[$0 - 1] } ?? "Month")
        }
    }

    private var dayPicker: some View {
        let days = Array(1...31)
        return Menu {
            ForEach(days, id: \.self) { day in
                Button(String(day)) { store.birthDay = day }
            }
        } label: {
            pickerLabel(store.birthDay.map { String($0) } ?? "Day")
        }
    }

    private func pickerLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(text == "Year" || text == "Month" || text == "Day" ? .white.opacity(0.35) : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Screen 4: Mini Profile

private struct MiniProfileScreen: View {
    @Bindable var store: OnboardingStore
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button {
                        withAnimation { store.step = 3 }
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
    @State private var businessSearch = ""
    @State private var searchResults: [BusinessSearchResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button {
                        withAnimation { store.step = 4 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                    Spacer()
                    Text("Your Business")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.top, 16)

                progressBar(step: store.totalSteps, total: store.totalSteps)

                // MARK: - Business Search
                VStack(alignment: .leading, spacing: 6) {
                    Text("Find your business")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Search by name or address")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.35))
                    TextField("Search for business...", text: $businessSearch)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: businessSearch) { _, query in
                            searchTask?.cancel()
                            guard query.count >= 2 else {
                                searchResults = []
                                return
                            }
                            searchTask = Task {
                                isSearching = true
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                guard !Task.isCancelled else { return }
                                await searchBusiness(query: query)
                                isSearching = false
                            }
                        }
                    if !businessSearch.isEmpty {
                        Button { businessSearch = ""; searchResults = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )

                // Search results
                if isSearching {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white.opacity(0.5))
                        Text("Searching...")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
                }

                if !searchResults.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(searchResults) { result in
                            Button {
                                store.businessName = result.name
                                store.businessAddress = result.address
                                store.businessDistrict = result.district
                                businessSearch = result.name
                                searchResults = []
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(MatchaTokens.Colors.accent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        Text(result.address)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.5))
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            if result.id != searchResults.last?.id {
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 46)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }

                // Selected business info
                if !store.businessName.isEmpty && searchResults.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(MatchaTokens.Colors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.businessName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            if !store.businessAddress.isEmpty {
                                Text(store.businessAddress)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        Spacer()
                        Button { store.businessName = ""; store.businessAddress = ""; businessSearch = "" } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .padding(14)
                    .background(MatchaTokens.Colors.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(MatchaTokens.Colors.accent.opacity(0.2), lineWidth: 1)
                    )
                }

                // MARK: - Category
                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(BusinessCategory.allCases) { category in
                            CategoryChip(title: category.title, isSelected: store.selectedCategory == category)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        store.selectedCategory = category
                                    }
                                }
                        }
                    }
                }

                // MARK: - Contact Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact info")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    MatchaTextField(
                        icon: "person",
                        placeholder: "First name",
                        text: $store.contactFirstName,
                        fieldState: .normal
                    )
                    MatchaTextField(
                        icon: "person",
                        placeholder: "Last name",
                        text: $store.contactLastName,
                        fieldState: .normal
                    )
                    MatchaTextField(
                        icon: "briefcase",
                        placeholder: "Position in company",
                        text: $store.contactPosition,
                        fieldState: .normal
                    )
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

    // MARK: - Google Places Search

    @MainActor
    private func searchBusiness(query: String) async {
        do {
            let places = try await GooglePlacesService.shared.searchPlaces(query: query)
            searchResults = places.map {
                BusinessSearchResult(
                    name: $0.name,
                    address: $0.address,
                    district: $0.district
                )
            }
        } catch GooglePlacesError.missingAPIKey {
            // Fallback to MapKit when key missing (dev builds)
            await searchBusinessMapKitFallback(query: query)
        } catch {
            searchResults = []
        }
    }

    @MainActor
    private func searchBusinessMapKitFallback(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -8.65, longitude: 115.17),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        request.resultTypes = .pointOfInterest

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems.prefix(6).map { item in
                let placemark = item.placemark
                let district = placemark.locality ?? placemark.subLocality ?? ""
                let address = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                return BusinessSearchResult(name: item.name ?? "Unknown", address: address, district: district)
            }
        } catch {
            searchResults = []
        }
    }
}

// MARK: - Business Search Result

private struct BusinessSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let district: String
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

// MARK: - Light Secure Field (with show/hide toggle)

private struct LightSecureFieldView: View {
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .font(.system(size: 16))
                .foregroundStyle(.black.opacity(0.35))
                .frame(width: 20)

            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                }
            }
            .font(.system(size: 16))
            .foregroundStyle(.black)
            .tint(.black)

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundStyle(.black.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.gray.opacity(0.15), lineWidth: 1)
        )
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
    var confirmPassword: String = ""
    var agreedToTerms: Bool = false
    var isLoginMode: Bool = false
    var selectedRole: Role = .blogger

    // Personal details (step 3)
    var selectedNationality: String = ""
    var selectedResidence: String = ""
    var selectedDistrict: String = ""
    var selectedGender: String = ""
    var birthYear: Int?
    var birthMonth: Int?
    var birthDay: Int?

    var name: String = ""
    var selectedCategory: BusinessCategory = .restaurantCafe
    var businessName: String = ""
    var businessAddress: String = ""
    var businessDistrict: String = ""
    var contactFirstName: String = ""
    var contactLastName: String = ""
    var contactPosition: String = ""
    var pickedPhoto: Image?
    var pickedPhotoData: Data?

    var isLoading: Bool = false
    var errorMessage: String?

    var emailFieldState: MatchaFieldState = .normal
    var passwordFieldState: MatchaFieldState = .normal
    var nameFieldState: MatchaFieldState = .normal

    var totalSteps: Int {
        selectedRole == .business ? 5 : 4
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

        if !isLoginMode {
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match."
                return
            }
            guard agreedToTerms else {
                errorMessage = "Please agree to the Terms of Service."
                return
            }
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

        withAnimation { step = 3 }
    }

    func advanceFromPersonalDetails() {
        errorMessage = nil

        guard !selectedNationality.isEmpty else {
            errorMessage = "Please select your nationality."
            return
        }
        guard !selectedGender.isEmpty else {
            errorMessage = "Please select your gender."
            return
        }

        withAnimation { step = 4 }
    }

    // Kept for reference — old advanceFromRegistration login branch
    private func _unused_login_placeholder() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
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

        withAnimation { step = 3 }
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
            withAnimation { step = 5 }
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
