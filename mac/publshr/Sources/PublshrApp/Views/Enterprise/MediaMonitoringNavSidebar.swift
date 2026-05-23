import SwiftUI

/// Secondary sidebar for Media Monitoring — feeds and workspaces list.
struct MediaMonitoringNavSidebar: View {
    var submenuWidth: CGFloat = LibraryUniversalSubmenu.width

    var body: some View {
        LibraryUniversalSubmenuContainer(width: submenuWidth) {
            VStack(alignment: .leading, spacing: 0) {
                LibraryUniversalSubmenu.sectionHeader("Coverage")
                sidebarRow("All coverage", icon: "dot.radiowaves.left.and.right", selected: true)
                sidebarRow("Saved clips", icon: "bookmark", selected: false)
                sidebarRow("Alerts", icon: "bell.badge", selected: false)
                Spacer(minLength: 0)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
        } footer: {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                Text("Open the desktop app for full monitoring")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: ChatClickUpDesign.footerHeight, alignment: .center)
        }
    }

    private func sidebarRow(_ title: String, icon: String, selected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .frame(width: ChatClickUpDesign.rowIconSize)
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
            Text(title)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: ChatClickUpDesign.rowHeight)
        .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
        .background(
            RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
        )
        .padding(.horizontal, 6)
    }
}
