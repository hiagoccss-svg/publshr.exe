import AppKit

/// Restores the primary IDE window after Dock click, minimize, or close (red button).
@MainActor
enum MainWindowPresenter {
    private static let minimumMainSize = NSSize(width: 900, height: 600)

    /// Called when the user re-activates the app (Dock icon, Cmd+Tab, etc.).
    static func restoreMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        let windows = NSApp.windows.filter { isRestorableAppWindow($0) }
        if windows.isEmpty {
            NotificationCenter.default.post(name: .publshrRestoreMainWindow, object: nil)
            return
        }

        for window in windows where window.isMiniaturized {
            window.deminiaturize(nil)
        }

        guard let main = selectMainWindow(from: windows) else { return }
        if main.isMiniaturized {
            main.deminiaturize(nil)
        }
        if !main.isVisible {
            main.orderFrontRegardless()
        }
        main.makeKeyAndOrderFront(nil)
        MainWindowChrome.apply(to: main)
    }

    private static func isRestorableAppWindow(_ window: NSWindow) -> Bool {
        guard window.canBecomeMain, !window.isSheet else { return false }
        let size = window.frame.size
        return size.width >= minimumMainSize.width && size.height >= minimumMainSize.height
    }

    private static func selectMainWindow(from windows: [NSWindow]) -> NSWindow? {
        if let saved = AppWindowStateStore.loadMainWindowFrame() {
            let targetArea = saved.width * saved.height
            if let closest = windows.min(by: {
                abs($0.frame.width * $0.frame.height - targetArea)
                    < abs($1.frame.width * $1.frame.height - targetArea)
            }) {
                return closest
            }
        }
        return windows.max(by: {
            $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
        })
    }
}
