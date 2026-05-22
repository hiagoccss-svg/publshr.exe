import AppKit

/// Transparent title bar + vibrancy-friendly window chrome for pop-out windows.
enum GlassWindowConfigurator {
    static func applyPopOutWindow(_ window: NSWindow) {
        window.styleMask = [.titled, .fullSizeContentView, .closable, .resizable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .normal
        window.appearance = NSAppearance(named: .aqua)
        if let content = window.contentView {
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }

    static func applyIncomingRingPanel(_ window: NSPanel) {
        window.styleMask = [.titled, .fullSizeContentView, .nonactivatingPanel, .closable]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.appearance = NSAppearance(named: .aqua)
        if let content = window.contentView {
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor.clear.cgColor
        }
    }
}
