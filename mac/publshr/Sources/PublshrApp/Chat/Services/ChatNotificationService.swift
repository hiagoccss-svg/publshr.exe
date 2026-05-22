import AppKit
import Foundation
import UserNotifications

/// Desktop-native notifications for chat (macOS Notification Center).
@MainActor
final class ChatNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ChatNotificationService()

    private(set) var isAuthorized = false
    private var registeredCategories = false

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func registerCategoriesIfNeeded() {
        guard !registeredCategories else { return }
        registeredCategories = true
        let categories: Set<UNNotificationCategory> = [
            makeCategory(.message),
            makeCategory(.mention),
            makeCategory(.reply),
        ]
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    private static let quickReplyActionId = "CHAT_QUICK_REPLY"

    private func makeCategory(_ kind: ChatNotificationCategory) -> UNNotificationCategory {
        let reply = UNTextInputNotificationAction(
            identifier: Self.quickReplyActionId,
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Message"
        )
        return UNNotificationCategory(
            identifier: kind.rawValue,
            actions: [reply],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    /// Requests macOS notification permission when still undetermined; refreshes `isAuthorized`.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        registerCategoriesIfNeeded()
        isAuthorized = await SystemPermissionStore.ensureNotificationAccess()
        return isAuthorized
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    /// Posts to Notification Center when authorized. `deliverBanner` controls in-app banner/sound while focused.
    func notify(
        title: String,
        body: String,
        channelId: UUID,
        messageId: UUID,
        category: ChatNotificationCategory = .message,
        deliverBanner: Bool = true
    ) {
        guard isAuthorized else { return }
        registerCategoriesIfNeeded()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = deliverBanner ? .default : nil
        content.categoryIdentifier = category.rawValue
        content.userInfo = [
            "channelId": channelId.uuidString,
            "messageId": messageId.uuidString,
            "category": category.rawValue,
        ]

        let request = UNNotificationRequest(
            identifier: "chat-\(messageId.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func setBadgeCount(_ count: Int) {
        guard isAuthorized else { return }
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard isAuthorized else { return [] }
        let info = notification.request.content.userInfo
        let channelId = (info["channelId"] as? String).flatMap(UUID.init(uuidString:))
        if shouldSuppressBanner(for: channelId) {
            return []
        }
        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let info = response.notification.request.content.userInfo
        guard let raw = info["channelId"] as? String, let channelId = UUID(uuidString: raw) else { return }

        if response.actionIdentifier == Self.quickReplyActionId,
           let textResponse = response as? UNTextInputNotificationResponse {
            let body = textResponse.userText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { return }
            await MainActor.run {
                onNotificationQuickReply?(channelId, body)
            }
            return
        }

        await MainActor.run {
            onNotificationTap?(channelId)
        }
    }

    /// Set from app bootstrap to route notification clicks to chat.
    var onNotificationTap: ((UUID) -> Void)?
    /// Quick reply from Notification Center (macOS text input action).
    var onNotificationQuickReply: ((UUID, String) -> Void)?

    private func shouldSuppressBanner(for channelId: UUID?) -> Bool {
        guard NSApp.isActive, let channelId else { return false }
        return ChatNotificationFocusState.shared.isViewingChannel(channelId)
    }
}

/// Tracks which channel is open in the main IDE so we can avoid duplicate banners while reading.
@MainActor
enum ChatNotificationFocusState {
    static let shared = ChatNotificationFocusStateStorage()
}

final class ChatNotificationFocusStateStorage {
    private(set) var activeChannelId: UUID?
    private(set) var appIsActive: Bool = true

    func setActiveChannel(_ channelId: UUID?) {
        activeChannelId = channelId
    }

    func setAppActive(_ active: Bool) {
        appIsActive = active
    }

    func isViewingChannel(_ channelId: UUID) -> Bool {
        appIsActive && activeChannelId == channelId
    }
}
