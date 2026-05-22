import Foundation

/// In-app notification feed item — mirrors a delivered macOS alert for the titlebar panel.
struct ChatInAppNotification: Identifiable, Equatable {
    let id: UUID
    let channelId: UUID
    let channelTitle: String
    let authorName: String
    let body: String
    let category: ChatNotificationCategory
    let createdAt: Date
    var isRead: Bool

    init(
        messageId: UUID,
        channelId: UUID,
        channelTitle: String,
        authorName: String,
        body: String,
        category: ChatNotificationCategory,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = messageId
        self.channelId = channelId
        self.channelTitle = channelTitle
        self.authorName = authorName
        self.body = body
        self.category = category
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
