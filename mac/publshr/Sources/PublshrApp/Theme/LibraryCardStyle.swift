import SwiftUI

/// White library cards with 18px radius and soft shadow (reference grid cards).
struct LibraryCardStyle: ViewModifier {
    var glass: Bool = false
    var padding: CGFloat = LibraryGlassDesign.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: LibraryGlassDesign.cardRadius, style: .continuous)
                    .fill(glass ? LibraryGlassDesign.cardGlassFill : LibraryGlassDesign.cardBackground)
                    .background {
                        if glass {
                            RoundedRectangle(cornerRadius: LibraryGlassDesign.cardRadius, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.cardRadius, style: .continuous)
                    .strokeBorder(LibraryGlassDesign.hairline, lineWidth: 1)
            )
            .shadow(color: LibraryGlassDesign.cardShadow, radius: 12, y: 4)
    }
}

struct GlassSidebarBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CursorMacShellDesign.sidebarBackground)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(CursorMacShellDesign.border)
                    .frame(width: 1)
            }
    }
}

struct LibraryPrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, LibraryGlassDesign.ctaPillHorizontal)
            .frame(maxWidth: .infinity)
            .frame(height: LibraryGlassDesign.ctaPillHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? LibraryGlassDesign.primaryCTAHover : LibraryGlassDesign.primaryCTA)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.08 : 0.16), radius: 10, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func libraryCard(glass: Bool = false, padding: CGFloat = LibraryGlassDesign.cardPadding) -> some View {
        modifier(LibraryCardStyle(glass: glass, padding: padding))
    }

    func glassSidebar() -> some View {
        modifier(GlassSidebarBackground())
    }
}
