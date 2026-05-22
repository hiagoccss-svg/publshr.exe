import SwiftUI

/// Cursor-style toolbar control — small icon, tight hit target, no heavy borders.
struct ToolbarIconButton: View {
    let systemName: String
    var enabled: Bool = true
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: CursorTheme.toolbarIconSize, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(enabled ? CursorTheme.toolbarIconForeground : CursorTheme.foregroundDim.opacity(0.35))
                .frame(width: CursorTheme.toolbarIconHitSize, height: CursorTheme.toolbarIconHitSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(help)
    }
}
