import AppKit
import SwiftUI

/// Desktop wallpaper bleed-through + layered glass for the library shell.
enum WorkspaceShellBackground {
    static let desktopBlurMaterial: NSVisualEffectView.Material = .underWindowBackground
    static let desktopBlurBlending: NSVisualEffectView.BlendingMode = .behindWindow
}

/// Full-window desktop vibrancy (user wallpaper shows through the app).
struct WorkspaceDesktopBackdrop: View {
    var body: some View {
        CursorMacShellDesign.columnChromeBackground
            .ignoresSafeArea()
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

/// Composer / bottom tools — frosted strip, not wired to sidebars (disconnected chrome).
struct GlassDisconnectedFooterBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(LibraryGlassDesign.sidebarGlassFill.opacity(0.35))
                    .background(.ultraThinMaterial)
            }
    }
}

extension View {
    func glassDisconnectedFooter() -> some View {
        modifier(GlassDisconnectedFooterBackground())
    }
}
