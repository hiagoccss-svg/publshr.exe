import SwiftUI

/// Reference top chrome: traffic lights band, back/forward/home, library tab, utility icons.
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    var safeAreaTop: CGFloat

    private var trafficBand: CGFloat {
        safeAreaTop > 0 ? safeAreaTop : CursorTheme.windowChromeTopInset
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: trafficBand)
            HStack(spacing: 8) {
                ToolbarIconButton(
                    systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                    help: "Toggle channel list"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tabStore.sidebarExpanded.toggle()
                    }
                }
                ToolbarIconButton(systemName: "chevron.left", enabled: canGoBack, help: "Back") {
                    navigateBack()
                }
                ToolbarIconButton(systemName: "chevron.right", enabled: canGoForward, help: "Forward") {
                    navigateForward()
                }
                ToolbarIconButton(systemName: "house", help: "Home") {
                    tabStore.openFromModule(module, activate: true)
                }

                libraryTab
                    .frame(maxWidth: .infinity)

                HStack(spacing: 2) {
                    ToolbarIconButton(systemName: "square.grid.2x2", help: "Spaces") {
                        module = .spaces
                        tabStore.openFromModule(.spaces, activate: true)
                    }
                    ToolbarIconButton(systemName: "list.bullet", help: "List") {
                        if module == .chat { chat.setSidebarLayout(.organized) }
                    }
                    ToolbarIconButton(systemName: "line.3.horizontal.decrease", help: "Filter") {
                        if module == .chat { chat.showSearchSheet = true }
                    }
                    ToolbarIconButton(systemName: "magnifyingglass", help: "Search") {
                        if module == .chat { chat.showSearchSheet = true }
                    }
                    ToolbarIconButton(systemName: "plus", help: "New tab") {
                        tabStore.openFromModule(module, activate: true)
                    }
                }

                ToolbarIconButton(systemName: "gearshape", help: "Settings") {
                    NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: LibraryGlassDesign.headerHeight)
        }
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(LibraryGlassDesign.headerGlass)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(LibraryGlassDesign.hairline).frame(height: 1)
        }
    }

    private var libraryTab: some View {
        HStack(spacing: 6) {
            Image(systemName: module == .chat ? "books.vertical" : "square.grid.2x2")
                .font(.system(size: 11, weight: .medium))
            Text(module == .chat ? "Library" : "Spaces")
                .font(.system(size: 12, weight: .semibold))
            Button {} label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .buttonStyle(.plain)
            .opacity(0.35)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }

    private var canGoBack: Bool {
        module == .chat ? chat.canNavigateBack : spaces.canNavigateBack
    }

    private var canGoForward: Bool {
        module == .chat ? chat.canNavigateForward : spaces.canNavigateForward
    }

    private func navigateBack() {
        if module == .chat { chat.navigateBack() }
        else { Task { await spaces.navigateBack() } }
    }

    private func navigateForward() {
        if module == .chat { chat.navigateForward() }
        else { Task { await spaces.navigateForward() } }
    }
}
