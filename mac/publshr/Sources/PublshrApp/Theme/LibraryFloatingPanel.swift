import SwiftUI

/// Main workspace column — frosted floating panel (reference masonry area behind glass).
struct LibraryFloatingPanelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: LibraryGlassDesign.contentPanelRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: LibraryGlassDesign.contentPanelRadius, style: .continuous)
                            .fill(LibraryGlassDesign.panelGlassFill)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.contentPanelRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.35),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: LibraryGlassDesign.panelShadow, radius: 28, y: 14)
            .clipShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.contentPanelRadius, style: .continuous))
    }
}

extension View {
    /// Floating glass panel for chat/spaces main column (desktop visible in outer margins).
    func libraryFloatingPanel() -> some View {
        modifier(LibraryFloatingPanelStyle())
    }
}
