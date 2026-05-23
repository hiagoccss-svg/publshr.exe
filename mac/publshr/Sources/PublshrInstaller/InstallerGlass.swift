import AppKit
import SwiftUI

/// Frosted desktop vibrancy for the installer window (wallpaper bleeds through).
struct InstallerGlassBackdrop: View {
    var body: some View {
        ZStack {
            InstallerVisualEffectBlur(
                material: .underWindowBackground,
                blendingMode: .behindWindow
            )
            Color.white.opacity(0.08)
        }
        .ignoresSafeArea()
    }
}

struct InstallerGlassCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
    }
}

struct InstallerVisualEffectBlur: NSViewRepresentable {
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

@MainActor
final class InstallerWindowStyle {
    static func apply(to window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.hasShadow = true
    }
}
