import Foundation

// MARK: - Auth Models

/// Mirrors backend `UserRead` schema
struct AuthUser: Codable, Sendable {
    let id: String
    let email: String
    let role: Role
    let fullName: String
    let isActive: Bool
    let verificationLevel: VerificationLevel
    let planTier: SubscriptionPlan
    let offerCredits: Int
    let createdAt: Date
    let updatedAt: Date
}

/// Mirrors backend `AuthTokenRead` schema
struct AuthResponse: Codable, Sendable {
    let accessToken: String
    let tokenType: String
    let user: AuthUser
}

// MARK: - Request Bodies

private struct LoginRequestBody: Encodable {
    let email: String
    let password: String
}

private struct RegisterRequestBody: Encodable {
    let email: String
    let password: String
    let role: Role
    let fullName: String
    let primaryPhotoUrl: String
    let category: String?
}

private struct VerifyRequestBody: Encodable {
    let instagramHandle: String
    let tiktokHandle: String?
    let audienceSize: Int
}

// MARK: - AuthService

/// Handles login, registration, token management, and verification.
/// Stores the JWT and session metadata in NetworkService secure storage.
@MainActor
final class AuthService: Sendable {

    static let shared = AuthService()
    private let network = NetworkService.shared
    private init() {}

    // MARK: - Login

    @MainActor
    func login(email: String, password: String) async throws -> AuthResponse {
        do {
            try ValidationService.validateAuth(email: email, password: password)
        } catch let error as ValidationError {
            throw NetworkError.domainError(code: "invalid_auth", message: error.localizedDescription)
        }

        let body = LoginRequestBody(email: email.trimmingCharacters(in: .whitespaces), password: password)
        let response: AuthResponse = try await network.request(.POST, path: "/auth/login", body: body)
        network.applySession(token: response.accessToken, userID: response.user.id, role: response.user.role)
        network.recordAuthenticatedEmail(response.user.email)
        return response
    }

    // MARK: - Register

    @MainActor
    func register(
        email: String,
        password: String,
        role: Role,
        fullName: String,
        primaryPhotoUrl: String = "https://placeholder.matcha.app/default.jpg",
        category: String? = nil
    ) async throws -> AuthResponse {
        do {
            try ValidationService.validateAuth(email: email, password: password, name: fullName)
        } catch let error as ValidationError {
            throw NetworkError.domainError(code: "invalid_auth", message: error.localizedDescription)
        }
        let trimmedName = ValidationService.sanitize(fullName)

        let body = RegisterRequestBody(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            role: role,
            fullName: trimmedName,
            primaryPhotoUrl: primaryPhotoUrl,
            category: category
        )
        let response: AuthResponse = try await network.request(.POST, path: "/auth/register", body: body)
        network.applySession(token: response.accessToken, userID: response.user.id, role: response.user.role)
        network.recordAuthenticatedEmail(response.user.email)
        return response
    }

    // MARK: - Fetch Current User

    @MainActor
    func fetchCurrentUser() async throws -> AuthUser {
        guard network.authToken != nil else {
            throw NetworkError.unauthorized
        }
        let user: AuthUser = try await network.request(.GET, path: "/auth/me")
        network.updateAuthenticatedUser(user)
        return user
    }

    // MARK: - Verify User

    @MainActor
    func verifyUser(instagramHandle: String, tiktokHandle: String? = nil, audienceSize: Int) async throws -> AuthUser {
        let trimmedHandle = instagramHandle.trimmingCharacters(in: .whitespaces)
        guard !trimmedHandle.isEmpty else {
            throw NetworkError.domainError(code: "invalid_handle", message: "Instagram handle cannot be empty.")
        }
        guard audienceSize >= 1 else {
            throw NetworkError.domainError(code: "invalid_audience", message: "Audience size must be at least 1.")
        }
        let body = VerifyRequestBody(
            instagramHandle: trimmedHandle,
            tiktokHandle: tiktokHandle,
            audienceSize: audienceSize
        )
        let user: AuthUser = try await network.request(.POST, path: "/auth/verify", body: body)
        return user
    }

    // MARK: - Sign Out

    @MainActor
    func signOut() {
        network.logout()
    }

    // MARK: - Helpers
}
