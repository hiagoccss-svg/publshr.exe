import SwiftUI

/// Shared enterprise sidebar row — compact icons, consistent spacing.
struct EnterpriseSidebarRow: View {
    let title: String
    let icon: String
    var selected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(selected ? Color.white : CursorTheme.foregroundMuted)
                    .frame(width: 14, alignment: .center)
                Text(title)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? Color.white : CursorTheme.foreground)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.vertical, LibraryGlassDesign.sidebarRowVertical)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.primaryCTA : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Soft horizontal rule between nav sections.
struct NavSidebarDivider: View {
    var body: some View {
        Rectangle()
            .fill(CursorTheme.hairline)
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }
}

/// Vertical rule in the workspace header between action groups.
struct HeaderActionDivider: View {
    var body: some View {
        Rectangle()
            .fill(CursorTheme.hairline)
            .frame(width: 1, height: 20)
    }
}
