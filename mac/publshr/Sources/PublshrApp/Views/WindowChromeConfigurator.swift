import AppKit
import SwiftUI

/// Cursor-style window: traffic lights share the unified toolbar row (no empty title strip).
struct WindowChromeConfigurator: NSViewRepresentable {
    final class Coordinator {
        weak var configuredWindow: NSWindow?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.isHidden = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window else { return }
        MainWindowChrome.apply(to: window)
        guard context.coordinator.configuredWindow !== window else { return }
        context.coordinator.configuredWindow = window
        MainWindowChrome.applyWithRetries(to: window)
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

        window.backgroundColor = NSColor(CursorTheme.titleBar)

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
            window.isMovableByWindowBackground = true
        }
        if !isSwiftUIHosting,
           window.responds(to: #selector(setter: NSWindow.toolbarStyle)) {
            window.toolbarStyle = .unifiedCompact
        }
        if window.responds(to: #selector(setter: NSWindow.titlebarSeparatorStyle)) {
            window.titlebarSeparatorStyle = .none
        }
        // titlebarAccessoryViewControllers KVC crashes on SwiftUI hosting windows (macOS 26+).
        if #available(macOS 14.0, *), !isSwiftUIHosting {
            if window.responds(to: #selector(setter: NSWindow.titlebarAccessoryViewControllers)) {
                window.titlebarAccessoryViewControllers = []
            }
        }
    }

    /// Re-apply after SwiftUI finishes configuring the hosting window.
    @MainActor
    static func applyWithRetries(to window: NSWindow?) {
        apply(to: window)
        guard let window else { return }
        for delay in [0.05, 0.15, 0.35, 0.75] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                apply(to: window)
            }
        }
    }
}
