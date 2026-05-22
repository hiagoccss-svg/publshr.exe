import SwiftUI

/// Collapsed primary column (~52px) — module icons only when the bar menu is minimized.
struct LibraryBarMenuIconRail: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule

    var body: some View {
        VStack(spacing: 8) {
            ForEach(AppModule.mainStrip) { item in
                Button {
                    module = item
                    tabStore.openFromModule(item, activate: true)
                } label: {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(module == item ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(module == item ? LibraryGlassDesign.sidebarSelection : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help(item.label)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
        .frame(maxHeight: .infinity)
    }
}
