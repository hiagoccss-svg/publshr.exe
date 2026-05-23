import SwiftUI

/// Secondary sidebar for Media Monitoring — filters wired to native Supabase workspace.
struct MediaMonitoringNavSidebar: View {
    @EnvironmentObject private var media: MediaMonitoringViewModel
    var submenuWidth: CGFloat = LibraryUniversalSubmenu.width

    var body: some View {
        LibraryUniversalSubmenuContainer(width: submenuWidth) {
            VStack(alignment: .leading, spacing: 0) {
                LibraryUniversalSubmenu.sectionHeader("Coverage")
                ForEach(MediaMonitoringFilter.allCases) { filter in
                    sidebarRow(filter.label, icon: filter.icon, selected: media.filter == filter) {
                        media.filter = filter
                        if let first = media.filteredResults.first {
                            media.selectResult(first.id)
                        } else {
                            media.selectedResultId = nil
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
        } footer: {
            HStack(spacing: 8) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                Text("Live Supabase coverage")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: ChatClickUpDesign.footerHeight, alignment: .center)
        }
    }

    private func sidebarRow(
        _ title: String,
        icon: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
}
