import Foundation

struct ChatThread: Hashable {
    let chatID: String
    let messages: [ConversationMessage]
    let activeDeal: Deal?
}
