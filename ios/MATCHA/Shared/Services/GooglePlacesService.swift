import Foundation

/// Thin wrapper over Google Places API (Text Search) for the business onboarding search.
///
/// Setup:
/// 1. Get an API key at https://console.cloud.google.com/google/maps-apis
/// 2. Enable "Places API" for the project
/// 3. Paste the key into `Config.apiKey` below (or plug it into Info.plist later)
/// 4. Restrict the key by bundle ID: `com.matcha.app`
@MainActor
final class GooglePlacesService {
    static let shared = GooglePlacesService()

    private enum Config {
        /// TODO: replace with real key from Google Cloud console (Places API enabled).
        static let apiKey: String = {
            if let fromInfo = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String,
               !fromInfo.isEmpty {
                return fromInfo
            }
            return ""
        }()
    }

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns up to 10 place results for `query`, biased to Bali.
    func searchPlaces(query: String) async throws -> [GooglePlace] {
        guard !Config.apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/textsearch/json")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "location", value: "-8.65,115.17"),   // Bali centre
            URLQueryItem(name: "radius", value: "50000"),            // 50 km
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "key", value: Config.apiKey)
        ]

        guard let url = components.url else { throw GooglePlacesError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GooglePlacesError.badResponse
        }

        let decoded = try JSONDecoder().decode(TextSearchResponse.self, from: data)

        switch decoded.status {
        case "OK":
            return decoded.results.prefix(10).map { result in
                GooglePlace(
                    placeId: result.place_id,
                    name: result.name,
                    address: result.formatted_address ?? "",
                    district: result.districtGuess,
                    latitude: result.geometry?.location.lat,
                    longitude: result.geometry?.location.lng,
                    photoReference: result.photos?.first?.photo_reference
                )
            }
        case "ZERO_RESULTS":
            return []
        case "REQUEST_DENIED":
            throw GooglePlacesError.requestDenied(decoded.error_message ?? "Request denied")
        case "OVER_QUERY_LIMIT":
            throw GooglePlacesError.overQuota
        case "INVALID_REQUEST":
            throw GooglePlacesError.invalidRequest
        default:
            throw GooglePlacesError.unknown(decoded.status)
        }
    }

    /// Returns a URL to fetch a place photo (Google redirects to the actual image).
    func photoURL(reference: String, maxWidth: Int = 800) -> URL? {
        guard !Config.apiKey.isEmpty else { return nil }
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")!
        components.queryItems = [
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "photo_reference", value: reference),
            URLQueryItem(name: "key", value: Config.apiKey)
        ]
        return components.url
    }
}

// MARK: - Domain

struct GooglePlace: Identifiable, Hashable, Sendable {
    var id: String { placeId }
    let placeId: String
    let name: String
    let address: String
    let district: String
    let latitude: Double?
    let longitude: Double?
    let photoReference: String?
}

enum GooglePlacesError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case badResponse
    case requestDenied(String)
    case overQuota
    case invalidRequest
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:        return "Google Places API key not configured. Add GOOGLE_PLACES_API_KEY to Info.plist."
        case .invalidURL:           return "Invalid Google Places request URL."
        case .badResponse:          return "Google Places returned a bad HTTP response."
        case .requestDenied(let m): return "Google Places denied the request: \(m)"
        case .overQuota:            return "Google Places quota exceeded for today."
        case .invalidRequest:       return "Invalid Google Places request."
        case .unknown(let s):       return "Google Places error: \(s)"
        }
    }
}

// MARK: - Raw API response DTOs

private struct TextSearchResponse: Decodable {
    let status: String
    let error_message: String?
    let results: [TextSearchResult]
}

private struct TextSearchResult: Decodable {
    let place_id: String
    let name: String
    let formatted_address: String?
    let geometry: Geometry?
    let photos: [PhotoRef]?
    let types: [String]?

    /// Best-effort district extraction from the formatted address.
    /// Google doesn't expose admin levels in Text Search without a separate
    /// Place Details call; we take the 2nd comma-separated segment ("Canggu").
    var districtGuess: String {
        guard let addr = formatted_address else { return "" }
        let parts = addr.split(separator: ",", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count >= 2 { return parts[1] }
        return parts.first ?? ""
    }
}

private struct Geometry: Decodable {
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
    let location: Location
}

private struct PhotoRef: Decodable {
    let photo_reference: String
}
