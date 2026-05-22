import AppKit
import SwiftUI

/// Dedicated glass call window (voice / video) — not a sheet over the IDE.
@MainActor
final class CallWindowManager: ObservableObject {
    static let shared = CallWindowManager()

    private var window: NSWindow?

    func present(calls: CallSignalingService, chat: ChatViewModel, auth: AuthViewModel) {
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
        window.title = calls.activeRoom?.title ?? "Call"
        window.setContentSize(NSSize(width: 520, height: 620))
        window.center()
        GlassWindowConfigurator.applyCallWindow(window)
        window.isReleasedWhenClosed = false

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                if self?.window === window {
                    self?.window = nil
                }
            }
        }

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
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

/// NSVisualEffectView bridge for desktop wallpaper bleed-through.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
