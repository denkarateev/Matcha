import Foundation
import Observation
import Security

// MARK: - Error Types

enum NetworkError: LocalizedError {
    case unauthorized                               // 401 — token cleared, redirect to login
    case forbidden                                  // 403
    case notFound                                   // 404
    case conflict                                   // 409
    case rateLimited                                // 429
    case serverError(Int)                           // 5xx
    case decodingError(Error)                       // JSON parse failed
    case networkError(Error)                        // No internet etc.
    case invalidURL                                 // Bad URL construction
    case domainError(code: String, message: String) // API business errors

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .conflict:
            return "A conflict occurred. The resource may already exist."
        case .rateLimited:
            return "Too many requests. Please slow down."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid request URL."
        case .domainError(_, let message):
            return message
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET    = "GET"
    case POST   = "POST"
    case PUT    = "PUT"
    case PATCH  = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - API Error Shape

/// Supports both legacy {"detail": "...", "error_code": "..."}
/// and current {"error": {"code": "...", "message": "..."}} API shapes.
private struct APIDomainError: Decodable {
    struct ErrorPayload: Decodable {
        let code: String
        let message: String
    }

    let detail: String?
    let errorCode: String?
    let error: ErrorPayload?

    enum CodingKeys: String, CodingKey {
        case detail
        case errorCode = "error_code"
        case error
    }

    var resolvedCode: String? {
        error?.code ?? errorCode
    }

    var resolvedMessage: String? {
        error?.message ?? detail
    }
}

// MARK: - NetworkService

@MainActor
@Observable
final class NetworkService {

    static let sessionInvalidatedNotification = Notification.Name("matcha.session.invalidated")

    static let shared = NetworkService()
    private init() {
        cachedAuthToken = loadSecureString(for: StorageKey.authToken)
        cachedCurrentUserID = loadSecureString(for: StorageKey.currentUserID)
        if let rawRole = loadSecureString(for: StorageKey.currentUserRole) {
            cachedCurrentUserRole = Role(rawValue: rawRole)
        }
    }
    private enum StorageKey {
        static let authToken = "matcha_auth_token"
        static let currentUserID = "matcha_current_user_id"
        static let currentUserRole = "matcha_current_user_role"
        static let lastAuthenticatedEmail = "matcha_last_authenticated_email"
    }
    private enum SecureSessionStore {
        static let service = "com.matcha.ios.session"

        static func string(for account: String) -> String? {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne,
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess, let data = item as? Data else {
                return nil
            }

            return String(data: data, encoding: .utf8)
        }

        static func set(_ value: String?, for account: String) {
            guard let value else {
                delete(account: account)
                return
            }

            let data = Data(value.utf8)
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ]

            let attributes: [CFString: Any] = [
                kSecValueData: data,
            ]

            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if updateStatus == errSecItemNotFound {
                var createQuery = query
                createQuery[kSecValueData] = data
                SecItemAdd(createQuery as CFDictionary, nil)
            }
        }

        static func delete(account: String) {
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        return URLSession(configuration: config)
    }()
    private var cachedAuthToken: String?
    private var cachedCurrentUserID: String?
    private var cachedCurrentUserRole: Role?
    private var cachedLastAuthenticatedEmail: String?
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase

        let iso3 = ISO8601DateFormatter()
        iso3.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]

        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // Try as-is (handles 3-digit fractional seconds)
            if let date = iso3.date(from: str) { return date }
            if let date = isoPlain.date(from: str) { return date }

            // Truncate microseconds (6 digits) to milliseconds (3 digits)
            // "2026-04-04T12:19:28.598489Z" → "2026-04-04T12:19:28.598Z"
            let truncated = str.replacingOccurrences(
                of: #"(\.\d{3})\d+"#,
                with: "$1",
                options: .regularExpression
            )
            if let date = iso3.date(from: truncated) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(str)"
            )
        }
        return d
    }()

    #if DEBUG
    var baseURL = URL(string: "http://188.253.19.166:8842/api/v1")!
    #else
    var baseURL = URL(string: "https://188.253.19.166:8842/api/v1")!
    #endif

    // MARK: - Token Storage

    var authToken: String? {
        get { cachedAuthToken ?? loadSecureString(for: StorageKey.authToken) }
        set {
            cachedAuthToken = newValue
            storeSecureString(newValue, for: StorageKey.authToken)
        }
    }

    var currentUserID: String? {
        get { cachedCurrentUserID ?? loadSecureString(for: StorageKey.currentUserID) }
        set {
            cachedCurrentUserID = newValue
            storeSecureString(newValue, for: StorageKey.currentUserID)
        }
    }

    var currentUserRole: Role? {
        get {
            if let cachedCurrentUserRole {
                return cachedCurrentUserRole
            }
            guard let rawValue = loadSecureString(for: StorageKey.currentUserRole) else {
                return nil
            }
            let role = Role(rawValue: rawValue)
            cachedCurrentUserRole = role
            return role
        }
        set {
            cachedCurrentUserRole = newValue
            storeSecureString(newValue?.rawValue, for: StorageKey.currentUserRole)
        }
    }

    var isAuthenticated: Bool { authToken != nil }

    func applySession(token: String, userID: String, role: Role) {
        authToken = token
        currentUserID = userID
        currentUserRole = role
    }

    var lastAuthenticatedEmail: String? {
        get { cachedLastAuthenticatedEmail ?? loadSecureString(for: StorageKey.lastAuthenticatedEmail) }
        set {
            cachedLastAuthenticatedEmail = newValue
            storeSecureString(newValue, for: StorageKey.lastAuthenticatedEmail)
        }
    }

    func recordAuthenticatedEmail(_ email: String) {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        lastAuthenticatedEmail = normalized.isEmpty ? nil : normalized
    }

    func shouldInvalidateLegacyDevelopmentSession(authenticatedEmail: String) -> Bool {
        let normalized = authenticatedEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized == "dev@matcha.app" else {
            return false
        }

        if authToken?.hasPrefix("dev-token:") == true {
            return true
        }

        return lastAuthenticatedEmail != normalized
    }

    func updateAuthenticatedUser(_ user: AuthUser) {
        currentUserID = user.id
        currentUserRole = user.role
    }

    func logout(notifySessionInvalidated: Bool = false) {
        let hadSession = authToken != nil || currentUserID != nil || currentUserRole != nil
        authToken = nil
        currentUserID = nil
        currentUserRole = nil
        lastAuthenticatedEmail = nil

        if notifySessionInvalidated, hadSession {
            NotificationCenter.default.post(name: Self.sessionInvalidatedNotification, object: nil)
        }
    }

    private func loadSecureString(for key: String) -> String? {
        if let secureValue = SecureSessionStore.string(for: key) {
            return secureValue
        }

        guard let legacyValue = UserDefaults.standard.string(forKey: key) else {
            return nil
        }

        SecureSessionStore.set(legacyValue, for: key)
        UserDefaults.standard.removeObject(forKey: key)
        return legacyValue
    }

    private func storeSecureString(_ value: String?, for key: String) {
        SecureSessionStore.set(value, for: key)
        if value == nil {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let urlRequest = try buildRequest(
            method: method,
            path: path,
            body: body,
            queryItems: queryItems
        )
        return try await execute(urlRequest)
    }

    /// Fire-and-forget request for endpoints that return no body (e.g. 204 No Content).
    func requestVoid(
        _ method: HTTPMethod,
        path: String,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(
            method: method,
            path: path,
            body: body,
            queryItems: nil
        )

        let data: Data
        let response: URLResponse

        debugLogRequest(urlRequest)

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            debugLogTransportError(error, for: urlRequest)
            throw NetworkError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.networkError(
                NSError(domain: "NetworkService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Non-HTTP response"])
            )
        }

        debugLogResponse(http, data: data, for: urlRequest)

        switch http.statusCode {
        case 200...299:
            return // Success, no body expected
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError(http.statusCode)
        }
    }

    // MARK: - Multipart Image Upload

    func upload<T: Decodable>(path: String, imageData: Data, filename: String) async throws -> T {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.path += path
        guard let url = components.url else { throw NetworkError.invalidURL }

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.POST.rawValue
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body

        return try await execute(urlRequest)
    }

    // MARK: - Request Builder

    private func buildRequest(
        method: HTTPMethod,
        path: String,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        // Append path segments safely
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        components.path += cleanPath
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.networkError(error)
            }
        }

        return urlRequest
    }

    // MARK: - Execute + Decode

    private func execute<T: Decodable>(_ urlRequest: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        debugLogRequest(urlRequest)

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            debugLogTransportError(error, for: urlRequest)
            throw NetworkError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            debugLogMalformedResponse(data: data, for: urlRequest)
            throw NetworkError.networkError(
                NSError(domain: "NetworkService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Non-HTTP response"])
            )
        }

        debugLogResponse(http, data: data, for: urlRequest)

        switch http.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }

        case 401:
            throw NetworkError.unauthorized

        case 403:
            throw NetworkError.forbidden

        case 404:
            throw NetworkError.notFound

        case 409:
            if let domainError = try? decoder.decode(APIDomainError.self, from: data),
               let message = domainError.resolvedMessage {
                throw NetworkError.domainError(
                    code: domainError.resolvedCode ?? "conflict",
                    message: message
                )
            }
            throw NetworkError.conflict

        case 429:
            throw NetworkError.rateLimited

        case 400, 402, 405...499:
            // Try to parse a DomainError body
            if let domainError = try? decoder.decode(APIDomainError.self, from: data),
               let message = domainError.resolvedMessage {
                throw NetworkError.domainError(
                    code: domainError.resolvedCode ?? "domain_error",
                    message: message
                )
            }
            throw NetworkError.serverError(http.statusCode)

        default:
            throw NetworkError.serverError(http.statusCode)
        }
    }

    private func debugLogRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<nil>"
        print("[MATCHA][API] -> \(method) \(url)")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("[MATCHA][API] headers: \(redactedHeaders(headers))")
        }

        if let bodyDescription = debugBodyDescription(for: request) {
            print("[MATCHA][API] body: \(bodyDescription)")
        }
        #endif
    }

    private func debugLogResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<nil>"
        print("[MATCHA][API] <- \(response.statusCode) \(method) \(url)")

        if !data.isEmpty {
            print("[MATCHA][API] response: \(debugString(from: data))")
        }
        #endif
    }

    private func debugLogTransportError(_ error: Error, for request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<nil>"
        print("[MATCHA][API] xx transport error \(method) \(url): \(error.localizedDescription)")
        #endif
    }

    private func debugLogMalformedResponse(data: Data, for request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "<nil>"
        print("[MATCHA][API] xx non-http response \(method) \(url)")
        if !data.isEmpty {
            print("[MATCHA][API] response: \(debugString(from: data))")
        }
        #endif
    }

    private func redactedHeaders(_ headers: [String: String]) -> [String: String] {
        var redacted = headers
        if let authorization = redacted["Authorization"], !authorization.isEmpty {
            redacted["Authorization"] = maskSensitiveValue(authorization)
        }
        return redacted
    }

    private func debugBodyDescription(for request: URLRequest) -> String? {
        guard let body = request.httpBody, !body.isEmpty else { return nil }

        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        if contentType.contains("multipart/form-data") {
            return "<multipart body: \(body.count) bytes>"
        }

        return debugString(from: body)
    }

    private func debugString(from data: Data) -> String {
        let rawString = String(data: data, encoding: .utf8) ?? "<\(data.count) bytes binary>"
        let sanitized = sanitizeDebugText(rawString)
        if sanitized.count > 4000 {
            let endIndex = sanitized.index(sanitized.startIndex, offsetBy: 4000)
            return sanitized[..<endIndex] + "…"
        }
        return sanitized
    }

    private func sanitizeDebugText(_ text: String) -> String {
        var sanitized = text
        let patterns = [
            #"("password"\s*:\s*")([^"]+)(")"#,
            #"("access_token"\s*:\s*")([^"]+)(")"#,
            #"("Authorization"\s*:\s*")([^"]+)(")"#
        ]

        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "$1<redacted>$3",
                options: .regularExpression
            )
        }

        return sanitized
    }

    private func maskSensitiveValue(_ value: String) -> String {
        guard value.count > 12 else { return "<redacted>" }
        let prefix = value.prefix(8)
        let suffix = value.suffix(4)
        return "\(prefix)…\(suffix)"
    }
}

// MARK: - AnyEncodable helper (type-erased Encodable for the generic body)

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { try value.encode(to: $0) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
