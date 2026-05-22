import AppKit
import SwiftUI

/// Pop out channels/DMs into isolated desktop windows (separate state from IDE panel).
@MainActor
final class ChatWindowManager: ObservableObject {
    static let shared = ChatWindowManager()

    private var windows: [UUID: NSWindow] = [:]
    private var sessions: [UUID: ChatChannelSession] = [:]

    var onSelectChannelInIDE: ((UUID) -> Void)?

    func openChannel(_ channel: ChatChannel, chat: ChatViewModel, auth: AuthViewModel) {
        if let existing = windows[channel.id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let session = ChatChannelSession(channel: channel, auth: auth, shared: chat)
        sessions[channel.id] = session

        let view = SessionPopOutRootView(session: session)
            .environmentObject(auth)
            .frame(minWidth: 420, minHeight: 520)

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = channel.displayTitle
        if let saved = AppWindowStateStore.loadChatPopOutFrame(channelId: channel.id) {
            window.setFrame(saved, display: true)
        } else {
            window.setContentSize(NSSize(width: 480, height: 640))
            window.center()
        }
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        GlassWindowConfigurator.applyPopOutWindow(window)
        window.isReleasedWhenClosed = false

        let channelId = channel.id
        windows[channelId] = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                AppWindowStateStore.saveChatPopOutFrame(channelId: channelId, frame: window.frame)
                self?.sessions[channelId]?.teardown()
                self?.sessions.removeValue(forKey: channelId)
                self?.windows.removeValue(forKey: channelId)
            }
        }

        window.makeKeyAndOrderFront(nil)
    }

    func openChannelFromNotification(_ channelId: UUID, chat: ChatViewModel, auth: AuthViewModel) {
        let all = chat.channels + chat.directMessages
        guard let channel = all.first(where: { $0.id == channelId }) else {
            onSelectChannelInIDE?(channelId)
            return
        }
        onSelectChannelInIDE?(channelId)
        openChannel(channel, chat: chat, auth: auth)
    }

    func forwardIncomingMessage(_ message: ChatMessage) {
        guard let session = sessions[message.channelId] else { return }
        session.mergeIncoming(message)
    }

    func forwardMessageUpdate(_ message: ChatMessage) {
        sessions[message.channelId]?.applyMessageUpdate(message)
    }

    func forwardMessageDelete(_ messageId: UUID) {
        for session in sessions.values {
            session.applyMessageDelete(messageId)
        }
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
        sessions.values.forEach { $0.teardown() }
        windows.removeAll()
        sessions.removeAll()
    }
}
