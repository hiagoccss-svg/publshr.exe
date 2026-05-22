import AppKit
import SwiftUI

@MainActor
final class SpacesWindowManager: ObservableObject {
    static let shared = SpacesWindowManager()

    private var windows: [UUID: NSWindow] = [:]

    func openSpace(_ space: SpaceRecord, spaces: SpacesViewModel, auth: AuthViewModel) {
        if let existing = windows[space.id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let view = SpacePopOutRootView(spaceId: space.id, spaces: spaces)
            .environmentObject(auth)
            .frame(minWidth: 900, minHeight: 620)

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = space.name
        window.setContentSize(NSSize(width: 1024, height: 720))
        window.center()
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.isReleasedWhenClosed = false

        let spaceId = space.id
        windows[spaceId] = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.windows.removeValue(forKey: spaceId)
            }
        }

        window.makeKeyAndOrderFront(nil)
        Task { await spaces.selectSpace(spaceId, recordHistory: false) }
    }

    func closeAll() {
        windows.values.forEach { $0.close() }
        windows.removeAll()
    }
}

private struct SpacePopOutRootView: View {
    let spaceId: UUID
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        SpacesRootView(spaces: spaces, topInset: 12, embedInPopOut: true)
            .task {
                await spaces.selectSpace(spaceId, recordHistory: false)
            }
    }
}
