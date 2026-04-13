import Foundation

// MARK: - UGC Post

/// A user-generated content post auto-populated from Content Proof submissions.
/// Business profiles display these in their UGC Gallery section.
struct UGCPost: Identifiable, Hashable {
    let id: UUID
    let bloggerName: String
    let bloggerPhotoURL: URL?
    let postURL: String            // Instagram/TikTok link
    let screenshotURL: URL?        // Stats screenshot
    let thumbnailURL: URL?         // Post thumbnail
    let submittedAt: Date
    var isHidden: Bool             // Business can hide individual posts

    var displayDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: submittedAt, relativeTo: Date())
    }
}

// MARK: - API DTO

struct UGCPostDTO: Decodable, Sendable {
    let id: String
    let bloggerName: String
    let bloggerPhotoUrl: String?
    let postUrl: String
    let screenshotUrl: String?
    let thumbnailUrl: String?
    let submittedAt: Date
    let isHidden: Bool

    func toDomain() -> UGCPost {
        UGCPost(
            id: UUID(uuidString: id) ?? UUID(),
            bloggerName: bloggerName,
            bloggerPhotoURL: bloggerPhotoUrl.flatMap { URL(string: $0) },
            postURL: postUrl,
            screenshotURL: screenshotUrl.flatMap { URL(string: $0) },
            thumbnailURL: thumbnailUrl.flatMap { URL(string: $0) },
            submittedAt: submittedAt,
            isHidden: isHidden
        )
    }
}
