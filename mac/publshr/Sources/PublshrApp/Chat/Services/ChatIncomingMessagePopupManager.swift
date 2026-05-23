import AppKit
import SwiftUI

struct ChatIncomingPopupPayload: Equatable {
    let messageId: UUID
    let channelId: UUID
    let channelTitle: String
    let authorName: String
    let preview: String
    let isMention: Bool
}

/// Teams-style floating toast when a new message arrives (desktop-only, user can disable).
@MainActor
final class ChatIncomingMessagePopupManager {
    static let shared = ChatIncomingMessagePopupManager()

    var onOpenChannel: ((UUID) -> Void)?
    var onQuickReply: ((UUID, String) -> Void)?

    private var panel: NSPanel?
    private var hosting: NSHostingController<ChatIncomingMessagePopupView>?
    private var autoDismissTask: Task<Void, Never>?
    private var currentChannelId: UUID?

    private init() {}

    func present(_ payload: ChatIncomingPopupPayload) {
        guard ChatUserPreferences.showIncomingMessagePopup else { return }
        dismiss()

        currentChannelId = payload.channelId
        let view = ChatIncomingMessagePopupView(
            payload: payload,
            onOpen: { [weak self] in
                self?.onOpenChannel?(payload.channelId)
                self?.dismiss()
            },
            onDismiss: { [weak self] in
                self?.dismiss()
            },
            onReply: { [weak self] text in
                self?.onQuickReply?(payload.channelId, text)
                self?.dismiss()
            }
        )
        let host = NSHostingController(rootView: view)
        hosting = host

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 132),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentViewController = host
        panel.hidesOnDeactivate = false
        self.panel = panel

        positionBottomRight(panel)
        panel.orderFrontRegardless()

        autoDismissTask?.cancel()
        autoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            guard !Task.isCancelled else { return }
            if currentChannelId == payload.channelId {
                dismiss()
            }
        }
    }

    func dismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        panel?.orderOut(nil)
        panel = nil
        hosting = nil
        currentChannelId = nil
    }

    private func positionBottomRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame else {
            panel.center()
            return
        }
        let size = panel.frame.size
        let margin: CGFloat = 20
        let origin = NSPoint(
            x: screen.maxX - size.width - margin,
            y: screen.minY + margin
        )
        panel.setFrameOrigin(origin)
    }
}

private struct ChatIncomingMessagePopupView: View {
    let payload: ChatIncomingPopupPayload
    let onOpen: () -> Void
    let onDismiss: () -> Void
    let onReply: (String) -> Void

    @State private var replyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: payload.isMention ? "at" : "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(CursorTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(payload.channelTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(payload.authorName)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                Spacer(minLength: 0)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                .buttonStyle(.plain)
            }

            Text(payload.preview)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("Quick reply…", text: $replyText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit { sendReply() }

                Button("Open", action: onOpen)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button("Later", action: onDismiss)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CursorTheme.panelBackground)
                .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(CursorTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func sendReply() {
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onReply(text)
        replyText = ""
    }
}
