struct ChatHome: Hashable {
    let newMatches: [UserProfile]
    let conversations: [ChatPreview]

    var actionRequiredConversations: [ChatPreview] {
        conversations.filter(\.requiresAction)
    }

    var activeDealCount: Int {
        conversations.filter { $0.activeDealStatus != nil }.count
    }
}
