import AppKit
import SwiftUI

/// Voice/video calls open in a dedicated window (not a sheet over the IDE).
@MainActor
final class CallWindowManager {
    static let shared = CallWindowManager()

    private var window: NSWindow?

    func present(
        calls: CallSignalingService,
        chat: ChatViewModel,
        auth: AuthViewModel
    ) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let root = CallRoomView()
            .environmentObject(calls)
            .environmentObject(chat)
            .environmentObject(auth)
            .frame(minWidth: 380, minHeight: 440)

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        let video = calls.activeRoom?.kind == "video"
        window.title = calls.activeRoom?.title ?? (video ? "Video call" : "Voice call")
        window.setContentSize(NSSize(width: 400, height: 460))
        window.center()
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false

        self.window = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            Task { @MainActor [weak self] in
                await calls.leaveCall()
                self?.window = nil
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        window?.close()
        window = nil
    }

    func closeAll() {
        dismiss()
    }
}
