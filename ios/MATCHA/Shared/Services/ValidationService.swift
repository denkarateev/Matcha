import Foundation

enum ValidationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emptyName
    case nameTooLong
    case emptyMessage
    case messageTooLong
    case invalidDealTerms

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters and include a letter and a number."
        case .emptyName:
            return "Name is required."
        case .nameTooLong:
            return "Name must be under 50 characters."
        case .emptyMessage:
            return "Message cannot be empty."
        case .messageTooLong:
            return "Message is too long."
        case .invalidDealTerms:
            return "Deal terms should describe both sides of the collaboration."
        }
    }
}

struct ValidationService {
    static func validateAuth(email: String, password: String, name: String? = nil) throws {
        if let name {
            let trimmedName = sanitize(name)
            guard !trimmedName.isEmpty else { throw ValidationError.emptyName }
            guard trimmedName.count <= 50 else { throw ValidationError.nameTooLong }
        }

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailPattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        guard trimmedEmail.wholeMatch(of: emailPattern) != nil else {
            throw ValidationError.invalidEmail
        }

        guard password.count >= 8,
              password.range(of: "[A-Za-z]", options: .regularExpression) != nil,
              password.range(of: "[0-9]", options: .regularExpression) != nil else {
            throw ValidationError.weakPassword
        }
    }

    static func validateMessage(_ text: String) throws -> String {
        let sanitized = sanitize(text)
        guard !sanitized.isEmpty else { throw ValidationError.emptyMessage }
        guard sanitized.count <= 1_000 else { throw ValidationError.messageTooLong }
        return sanitized
    }

    static func validateDealTerms(offer: String, receive: String) throws -> (offer: String, receive: String) {
        let sanitizedOffer = sanitize(offer)
        let sanitizedReceive = sanitize(receive)
        guard !sanitizedOffer.isEmpty, !sanitizedReceive.isEmpty else {
            throw ValidationError.invalidDealTerms
        }
        return (sanitizedOffer, sanitizedReceive)
    }

    static func sanitize(_ text: String) -> String {
        let stripped = text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
