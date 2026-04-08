import Foundation

enum ConversationMessageBody: Hashable {
    case text(String)
    case system(String)
    case deal(Deal)
    case image(caption: String?)
}

struct ConversationMessage: Identifiable, Hashable {
    let id: String
    let chatID: String
    let senderID: String
    let body: ConversationMessageBody
    let createdAt: Date
    let isOutgoing: Bool
}

struct SendChatMessageRequest: Encodable, Sendable {
    let text: String?
    let imageURL: String?
    let dealCardId: String?

    init(text: String? = nil, imageURL: String? = nil, dealCardId: String? = nil) {
        self.text = text
        self.imageURL = imageURL
        self.dealCardId = dealCardId
    }
}
