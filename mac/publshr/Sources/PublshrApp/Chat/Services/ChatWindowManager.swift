import AppKit
import SwiftUI

/// Slack-style dedicated chat windows: borderless, resizable, custom close — main app stays open.
@MainActor
final class ChatWindowManager: ObservableObject {
    static let shared = ChatWindowManager()

    private struct WindowEntry {
        let window: NSWindow
        let session: ChatChannelSession
    }

    private var entries: [UUID: WindowEntry] = [:]

    /// Open notification / deep link handler (wired from ChatNotificationService).
    var openChannelHandler: ((UUID) -> Void)?

    private init() {}

    func openChannel(
        _ channel: ChatChannel,
        auth: AuthViewModel,
        shared: ChatViewModel
    ) {
        if let existing = entries[channel.id] {
            existing.window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let session = ChatChannelSession(channel: channel, auth: auth, shared: shared)
        let rootView = DedicatedChatWindowView(session: session) {
            self.closeWindow(channelId: channel.id)
        }
        .environmentObject(auth)
        .preferredColorScheme(.dark)

        let hosting = NSHostingController(rootView: rootView)
        let window = ChatFloatingWindow(
            contentViewController: hosting,
            channelTitle: channel.displayTitle
        )
        window.setContentSize(NSSize(width: 520, height: 720))
        window.minSize = NSSize(width: 380, height: 480)
        window.center()
        window.isReleasedWhenClosed = false

        entries[channel.id] = WindowEntry(window: window, session: session)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                session.teardown()
                self?.entries.removeValue(forKey: channel.id)
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openChannelById(_ channelId: UUID, shared: ChatViewModel, auth: AuthViewModel) {
        let all = shared.channels + shared.directMessages
        guard let channel = all.first(where: { $0.id == channelId }) else { return }
        openChannel(channel, auth: auth, shared: shared)
    }

    func routeIncomingMessage(_ message: ChatMessage) {
        if let entry = entries[message.channelId] {
            entry.session.mergeIncoming(message)
        }
    }

    func routeMessageUpdate(_ message: ChatMessage) {
        entries[message.channelId]?.session.applyMessageUpdate(message)
    }

    func routeMessageDelete(_ messageId: UUID, channelId: UUID) {
        entries[channelId]?.session.applyMessageDelete(messageId)
    }

    func closeWindow(channelId: UUID) {
        entries[channelId]?.window.close()
    }

    func closeAll() {
        entries.values.forEach { $0.window.close() }
        entries.removeAll()
    }
}

// MARK: - Borderless resizable window (no system title bar)

final class ChatFloatingWindow: NSWindow {
    init(contentViewController: NSViewController, channelTitle: String) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 720),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.contentViewController = contentViewController
        title = channelTitle
        isMovableByWindowBackground = true
        backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1)
        hasShadow = true
        isOpaque = true
        level = .normal
        collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Dedicated window UI

struct DedicatedChatWindowView: View {
    @ObservedObject var session: ChatChannelSession
    let onClose: () -> Void
    @State private var showVoice = false

    var body: some View {
        VStack(spacing: 0) {
            ChatFloatingTitleBar(
                title: session.channel.displayTitle,
                subtitle: session.channel.description,
                typingLabel: session.typingLabel,
                onClose: onClose
            )

            HStack(spacing: 0) {
                SessionConversationView(session: session, showVoice: $showVoice)
                if session.showThreadPanel {
                    SessionThreadPanel(session: session)
                }
            }
        }
        .background(CursorTheme.chatBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
        .padding(6)
        .sheet(isPresented: $showVoice) {
            ChatVoiceRecorderSheetForSession(session: session)
        }
    }
}

/// Minimal chrome: channel name + close (no macOS title bar).
struct ChatFloatingTitleBar: View {
    let title: String
    let subtitle: String?
    let typingLabel: String?
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                if let typingLabel {
                    Text(typingLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.accent)
                } else if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(width: 28, height: 28)
                    .background(CursorTheme.inputBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close window")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(CursorTheme.panelBackground)
    }
}
