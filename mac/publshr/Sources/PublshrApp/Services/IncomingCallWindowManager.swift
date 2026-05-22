import AppKit
import SwiftUI

/// Floating incoming-call ring (accept / decline).
@MainActor
final class IncomingCallWindowManager: ObservableObject {
    static let shared = IncomingCallWindowManager()

    private var panel: NSPanel?
    private var ringTimer: Timer?

    func present(
        invite: IncomingCallInvite,
        calls: CallSignalingService,
        chat: ChatViewModel,
        auth: AuthViewModel
    ) {
        close()
        NSSound(named: "Glass")?.play()

        let root = IncomingCallRingView(invite: invite)
            .environmentObject(calls)
            .environmentObject(chat)
            .environmentObject(auth)
            .frame(width: 360, height: 220)

        let hosting = NSHostingController(rootView: root)
        let panel = NSPanel(contentViewController: hosting)
        panel.setContentSize(NSSize(width: 360, height: 220))
        GlassWindowConfigurator.applyIncomingRingPanel(panel)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.center()
        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        ringTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            NSSound(named: "Glass")?.play()
        }
    }

    func close() {
        ringTimer?.invalidate()
        ringTimer = nil
        panel?.close()
        panel = nil
    }
}
