import Foundation
import UserNotifications

/// Desktop-native notifications for chat (macOS Notification Center).
@MainActor
final class ChatNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ChatNotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func notify(
        title: String,
        body: String,
        channelId: UUID,
        messageId: UUID? = nil,
        category: ChatNotificationCategory = .message,
        silent: Bool = false
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = silent ? nil : .default
        content.categoryIdentifier = category.rawValue
        content.userInfo = [
            "channelId": channelId.uuidString,
            "messageId": messageId?.uuidString as Any,
            "category": category.rawValue,
        ].compactMapValues { $0 }

        let request = UNNotificationRequest(
            identifier: "\(channelId.uuidString)-\(messageId?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func setBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info["channelId"] as? String, let channelId = UUID(uuidString: raw) else { return }
        await MainActor.run {
            onNotificationTap?(channelId)
        }
    }

    /// Set from app bootstrap to route notification clicks to chat.
    var onNotificationTap: ((UUID) -> Void)?
}

enum ChatNotificationCategory: String {
    case message
    case mention
    case reply
    case approval
    case voiceNote = "voice_note"
    case assignment
    case channelInvite = "channel_invite"
    case fileUpload = "file_upload"
    case clientMessage = "client_message"
    case reminder
}
