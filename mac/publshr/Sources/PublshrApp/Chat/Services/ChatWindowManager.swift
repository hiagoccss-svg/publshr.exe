import AppKit
import SwiftUI

/// Phase 3: pop out channels/DMs into separate desktop windows.
@MainActor
final class ChatWindowManager: ObservableObject {
    static let shared = ChatWindowManager()
    private var windows: [UUID: NSWindow] = [:]

    func openChannel(_ channel: ChatChannel, chat: ChatViewModel, auth: AuthViewModel) {
        if let existing = windows[channel.id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let view = PopOutChatView(channel: channel, chat: chat)
            .environmentObject(auth)
            .frame(minWidth: 420, minHeight: 520)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = channel.displayTitle
        window.setContentSize(NSSize(width: 480, height: 640))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        let channelId = channel.id
        windows[channelId] = window
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.windows.removeValue(forKey: channelId)
            }
        }
        window.makeKeyAndOrderFront(nil)
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
        windows.removeAll()
    }
}

struct PopOutChatView: View {
    let channel: ChatChannel
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            ChatConversationView(chat: chat)
        }
        .onAppear { chat.selectChannel(channel) }
    }
}
