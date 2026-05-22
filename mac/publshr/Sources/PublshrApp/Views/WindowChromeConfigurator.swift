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
        guard context.coordinator.configuredWindow !== window else { return }
        context.coordinator.configuredWindow = window
        MainWindowChrome.apply(to: window)
    }
}

/// Defensive window styling — SwiftUI hosting windows reject some titlebar KVC on macOS 26+.
enum MainWindowChrome {
    @MainActor
    static func apply(to window: NSWindow?) {
        guard let window, window.isKind(of: NSWindow.self) else { return }

        let className = NSStringFromClass(type(of: window))
        let isSwiftUIHosting = className.contains("Hosting") || className.contains("SwiftUI")

        window.backgroundColor = NSColor(CursorTheme.editorBackground)

        if isSwiftUIHosting {
            // hiddenTitleBar already owns chrome; only set properties that are safe on hosting windows.
            if window.responds(to: #selector(setter: NSWindow.isMovableByWindowBackground)) {
                window.isMovableByWindowBackground = true
            }
            return
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
            window.isMovableByWindowBackground = true
        }
        if window.responds(to: #selector(setter: NSWindow.toolbarStyle)) {
            window.toolbarStyle = .unifiedCompact
        }
        if window.responds(to: #selector(setter: NSWindow.titlebarSeparatorStyle)) {
            window.titlebarSeparatorStyle = .none
        }
        if #available(macOS 14.0, *) {
            if window.responds(to: #selector(setter: NSWindow.titlebarAccessoryViewControllers)) {
                window.titlebarAccessoryViewControllers = []
            }
        }
    }
}
