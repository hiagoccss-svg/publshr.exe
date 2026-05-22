import SwiftUI

/// ClickUp-style footer actions — text on submenu chrome, no pill boxes.
struct LibrarySubmenuTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(
                configuration.isPressed ? LibraryGlassDesign.inkMuted : LibraryGlassDesign.inkSecondary
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 30)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
