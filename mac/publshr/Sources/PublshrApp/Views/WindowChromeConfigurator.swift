import AppKit
import SwiftUI

/// Cursor-style window: traffic lights share the unified toolbar row (no empty title strip).
struct WindowChromeConfigurator: NSViewRepresentable {
    final class Coordinator {
        weak var configuredWindow: NSWindow?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> TitlebarWindowObserverView {
        TitlebarWindowObserverView()
    }

    func updateNSView(_ nsView: TitlebarWindowObserverView, context: Context) {
        guard let window = nsView.window else { return }
        MainWindowChrome.apply(to: window)
        TitlebarChromeBridge.shared.attachWindow(window)
        context.coordinator.configuredWindow = window
    }
}

/// Notifies when the window frame changes so the titlebar accessory can resize.
final class TitlebarWindowObserverView: NSView {
    override var isHidden: Bool {
        get { true }
        set { super.isHidden = true }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        MainWindowChrome.apply(to: window)
        TitlebarChromeBridge.shared.attachWindow(window)
    }

    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        guard let window else { return }
        TitlebarChromeBridge.shared.attachWindow(window)
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
        if !isSwiftUIHosting,
           window.responds(to: #selector(setter: NSWindow.toolbarStyle)) {
            window.toolbarStyle = .unifiedCompact
        }
        if window.responds(to: #selector(setter: NSWindow.titlebarSeparatorStyle)) {
            window.titlebarSeparatorStyle = .none
        }
        tightenTopSafeArea(for: window)
        // Only clear legacy accessories on plain AppKit windows (SwiftUI hosting crashes on KVC reset).
        if #available(macOS 14.0, *), !isSwiftUIHosting {
            if window.responds(to: #selector(setter: NSWindow.titlebarAccessoryViewControllers)) {
                let keep = window.titlebarAccessoryViewControllers.filter {
                    $0.identifier == TitlebarChromeBridge.accessoryIdentifier
                }
                if keep.count != window.titlebarAccessoryViewControllers.count {
                    window.titlebarAccessoryViewControllers = keep
                }
            }
        }
    }

    /// Counteract inflated SwiftUI top safe-area so content starts below the unified titlebar.
    @MainActor
    private static func tightenTopSafeArea(for window: NSWindow) {
        guard let contentView = window.contentView else { return }
        let reportedTop = contentView.safeAreaInsets.top
        let target = AppWindowChromeMetrics.trafficLightRowHeight
        var extra = contentView.additionalSafeAreaInsets
        let desiredTop = reportedTop > target + 0.5 ? target - reportedTop : 0
        guard abs(extra.top - desiredTop) > 0.5 else { return }
        extra.top = desiredTop
        contentView.additionalSafeAreaInsets = extra
    }

    /// Re-apply after SwiftUI finishes configuring the hosting window.
    @MainActor
    static func applyWithRetries(to window: NSWindow?) {
        apply(to: window)
        guard let window else { return }
        TitlebarChromeBridge.shared.attachWindow(window)
        for delay in [0.05, 0.15, 0.35, 0.75, 1.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                apply(to: window)
                TitlebarChromeBridge.shared.attachWindow(window)
            }
        }
    }
}
