import Foundation
import Observation

// MARK: - TranslationService

/// Provides language detection and translation capabilities for chat messages.
/// MVP uses heuristic-based language detection (Cyrillic, CJK, Latin scripts).
/// Production path: Apple Translation framework or external API.
@MainActor
@Observable
final class TranslationService {
    static let shared = TranslationService()

    /// User preference: auto-translate messages (persisted in UserDefaults).
    var autoTranslateEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoTranslateEnabled, forKey: Self.autoTranslateKey)
        }
    }

    /// Cache of translated texts keyed by original text hash.
    private var translationCache: [Int: String] = [:]

    private static let autoTranslateKey = "matcha_auto_translate_enabled"

    private init() {
        self.autoTranslateEnabled = UserDefaults.standard.object(forKey: Self.autoTranslateKey) as? Bool ?? true
    }

    // MARK: - Language Detection (Heuristic)

    /// Detects the primary language of a text using character-set heuristics.
    /// Returns an ISO 639-1 code: "ru", "zh", "ja", "ko", "id", "en", or nil if undetermined.
    func detectLanguage(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var cyrillicCount = 0
        var latinCount = 0
        var cjkCount = 0
        var totalLetters = 0

        for scalar in trimmed.unicodeScalars {
            guard scalar.properties.isAlphabetic else { continue }
            totalLetters += 1

            if isCyrillic(scalar) {
                cyrillicCount += 1
            } else if isCJK(scalar) {
                cjkCount += 1
            } else if isLatin(scalar) {
                latinCount += 1
            }
        }

        guard totalLetters > 0 else { return nil }

        let cyrillicRatio = Double(cyrillicCount) / Double(totalLetters)
        let cjkRatio = Double(cjkCount) / Double(totalLetters)

        // Cyrillic dominant -> Russian
        if cyrillicRatio > 0.3 {
            return "ru"
        }

        // CJK dominant -> skip (too ambiguous between zh/ja/ko for MVP)
        if cjkRatio > 0.3 {
            return "zh"
        }

        // Latin script — check for Indonesian common words
        let lowered = trimmed.lowercased()
        let indonesianMarkers = ["saya", "anda", "kami", "dengan", "untuk", "yang", "adalah", "dari", "ini", "itu", "bisa", "tidak", "sudah", "akan", "bali", "terima", "kasih"]
        let words = Set(lowered.components(separatedBy: .whitespacesAndNewlines))
        let idHits = indonesianMarkers.filter { words.contains($0) }.count
        if idHits >= 2 {
            return "id"
        }

        // Default Latin -> English
        return "en"
    }

    /// Returns a human-readable language name for an ISO 639-1 code.
    func languageName(for code: String) -> String {
        switch code {
        case "ru": return "Russian"
        case "zh": return "Chinese"
        case "ja": return "Japanese"
        case "ko": return "Korean"
        case "id": return "Indonesian"
        case "en": return "English"
        case "es": return "Spanish"
        case "fr": return "French"
        case "de": return "German"
        case "pt": return "Portuguese"
        default: return code.uppercased()
        }
    }

    /// Returns the current device interface language code (e.g. "en", "ru").
    var currentInterfaceLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    // MARK: - Translation (MVP Placeholder)

    /// For MVP: returns nil (translation not yet available).
    /// In production: call Apple's Translation framework or an external API.
    func translate(_ text: String, to targetLanguage: String) async -> String? {
        // Check cache first
        let cacheKey = text.hashValue ^ targetLanguage.hashValue
        if let cached = translationCache[cacheKey] {
            return cached
        }

        // MVP: return placeholder
        // TODO: Replace with Apple Translation framework or API call
        return nil
    }

    // MARK: - Convenience

    /// Returns whether a message should show a translation prompt.
    /// True if auto-translate is on and detected language differs from interface language.
    func shouldShowTranslationPrompt(for text: String) -> Bool {
        guard autoTranslateEnabled else { return false }
        guard let detected = detectLanguage(text) else { return false }
        return detected != currentInterfaceLanguage
    }

    // MARK: - Unicode Helpers

    private func isCyrillic(_ scalar: Unicode.Scalar) -> Bool {
        (0x0400...0x04FF).contains(scalar.value) ||
        (0x0500...0x052F).contains(scalar.value)
    }

    private func isCJK(_ scalar: Unicode.Scalar) -> Bool {
        (0x4E00...0x9FFF).contains(scalar.value) ||  // CJK Unified
        (0x3400...0x4DBF).contains(scalar.value) ||  // CJK Extension A
        (0x3040...0x309F).contains(scalar.value) ||  // Hiragana
        (0x30A0...0x30FF).contains(scalar.value) ||  // Katakana
        (0xAC00...0xD7AF).contains(scalar.value)     // Hangul Syllables
    }

    private func isLatin(_ scalar: Unicode.Scalar) -> Bool {
        (0x0041...0x005A).contains(scalar.value) ||  // A-Z
        (0x0061...0x007A).contains(scalar.value) ||  // a-z
        (0x00C0...0x024F).contains(scalar.value)     // Latin Extended
    }
}
