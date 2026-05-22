import AppKit
import SwiftUI

/// Cursor-style window: traffic lights share the unified toolbar row (no empty title strip).
struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        MainWindowChrome.apply(to: window)
    }
}

/// Frameless chrome: traffic lights overlay the app header; no separate grey title strip.
enum MainWindowChrome {
    @MainActor
    static func apply(to window: NSWindow?) {
        guard let window, window.isKind(of: NSWindow.self) else { return }

        let className = NSStringFromClass(type(of: window))
        let isPlainAppKitWindow = className == "NSWindow" || className == "NSPanel"
        let isSwiftUIHosting =
            !isPlainAppKitWindow
            || className.contains("Hosting")
            || className.contains("SwiftUI")

        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        if #available(macOS 14.0, *) {
            window.toolbar = nil
        }

        if window.responds(to: #selector(setter: NSWindow.titlebarAppearsTransparent)) {
            window.titlebarAppearsTransparent = true
        }
        if window.responds(to: #selector(setter: NSWindow.titleVisibility)) {
            window.titleVisibility = .hidden
        }
        var mask = window.styleMask
        if !mask.contains(.fullSizeContentView) {
            mask.insert(.fullSizeContentView)
            window.styleMask = mask
        }
        if window.responds(to: #selector(setter: NSWindow.isMovableByWindowBackground)) {
            window.isMovableByWindowBackground = false
        }
        if let content = window.contentView {
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor.clear.cgColor
        }
        if window.responds(to: #selector(setter: NSWindow.toolbarStyle)) {
            window.toolbarStyle = .unified
        }
        if window.responds(to: #selector(setter: NSWindow.titlebarSeparatorStyle)) {
            window.titlebarSeparatorStyle = .none
        }

        TrafficLightLayoutStore.shared.apply(to: window)
    }

    @MainActor
    static func applyWithRetries(to window: NSWindow?) {
        apply(to: window)
        guard let window else { return }
        for delay in [0.05, 0.15, 0.35, 0.75, 1.5, 2.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                apply(to: window)
            }
        }
    }
}
