import AppKit
import SwiftUI

/// Desktop wallpaper bleed-through + layered glass for the library shell.
enum WorkspaceShellBackground {
    static let desktopBlurMaterial: NSVisualEffectView.Material = .sidebar
    static let desktopBlurBlending: NSVisualEffectView.BlendingMode = .behindWindow
}

/// Full-window desktop vibrancy (user wallpaper shows through the app).
struct WorkspaceDesktopBackdrop: View {
    var body: some View {
        VisualEffectBlur(
            material: WorkspaceShellBackground.desktopBlurMaterial,
            blendingMode: WorkspaceShellBackground.desktopBlurBlending
        )
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

/// Main column: transparent glass over the desktop; content cards float on top.
struct GlassMainContentBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(LibraryGlassDesign.workspaceGlass)
                    .background(.thinMaterial)
            }
    }
}

/// Composer / bottom tools — frosted strip, not wired to sidebars (disconnected chrome).
struct GlassDisconnectedFooterBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(LibraryGlassDesign.cardGlassFill.opacity(0.55))
                    .background(.ultraThinMaterial)
            }
    }
}

extension View {
    func glassMainContent() -> some View {
        modifier(GlassMainContentBackground())
    }

    func glassDisconnectedFooter() -> some View {
        modifier(GlassDisconnectedFooterBackground())
    }
}
