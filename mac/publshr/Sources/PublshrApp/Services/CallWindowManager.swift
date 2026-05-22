import AppKit
import SwiftUI

/// Dedicated glass call window (voice / video) — not a sheet over the IDE.
@MainActor
final class CallWindowManager: ObservableObject {
    static let shared = CallWindowManager()

    private var window: NSWindow?

    func present(
        calls: CallSignalingService,
        chat: ChatViewModel,
        auth: AuthViewModel
    ) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let root = CallRoomRootView()
            .environmentObject(calls)
            .environmentObject(chat)
            .environmentObject(auth)
            .frame(minWidth: 360, minHeight: 480)

        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        let video = calls.activeRoom?.kind == "video"
        window.title = calls.activeRoom?.title ?? (video ? "Video call" : "Voice call")
        window.setContentSize(NSSize(width: 520, height: 620))
        window.center()
        GlassWindowConfigurator.applyCallWindow(window)
        window.isReleasedWhenClosed = false

        self.window = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            DispatchQueue.main.async { [weak self] in
                Task { await calls.leaveCall() }
                if self?.window === window {
                    self?.window = nil
                }
            }
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        dismiss()
    }

    func dismiss() {
        window?.close()
        window = nil
    }

    func closeAll() {
        dismiss()
    }
}

/// Root hosted in the glass call `NSWindow`.
struct CallRoomRootView: View {
    @EnvironmentObject private var calls: CallSignalingService

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            CallRoomView()
                .padding(12)
        }
        .preferredColorScheme(.light)
    }
}

