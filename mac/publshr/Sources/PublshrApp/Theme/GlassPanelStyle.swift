import SwiftUI

/// Frosted glass panels — desktop shows through subtly (ClickUp / Windows 11 style).
struct GlassPanelStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.72

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(opacity))
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.25),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 24, y: 12)
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 16, opacity: Double = 0.72) -> some View {
        modifier(GlassPanelStyle(cornerRadius: cornerRadius, opacity: opacity))
    }
}

/// White ClickUp-style dropdown / context menu surfaces.
struct EnterpriseMenuSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(CursorTheme.border, lineWidth: 1)
            )
    }
}
