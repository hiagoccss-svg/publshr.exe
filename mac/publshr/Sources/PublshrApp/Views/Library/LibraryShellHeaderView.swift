import SwiftUI

/// Reference top chrome: traffic lights band, back/forward/home, utility icons.
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    var safeAreaTop: CGFloat

    /// Single toolbar row — icons sit to the right of macOS traffic lights (Pinterest / library reference).
    private var toolbarHeight: CGFloat {
        max(LibraryGlassDesign.headerHeight, CursorTheme.workspaceHeaderHeight)
    }

    var body: some View {
        HStack(spacing: 8) {
            ToolbarIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: "Toggle submenu"
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }
            if module == .chat || module == .spaces {
                ToolbarIconButton(
                    systemName: submenuFocusIcon,
                    help: "Toggle focus mode"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if module == .chat { chat.chatFocusMode.toggle() }
                        else { spaces.spacesFocusMode.toggle() }
                    }
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

            Spacer(minLength: 0)

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
            }

            ToolbarIconButton(systemName: "gearshape", help: "Settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            }
        }
        .padding(.leading, CursorTheme.trafficLightLeadingPadding)
        .padding(.trailing, 12)
        .padding(.top, safeAreaTop > 0 ? 0 : 4)
        .frame(height: toolbarHeight + (safeAreaTop > 0 ? safeAreaTop : 0))
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

    private var submenuFocusIcon: String {
        switch module {
        case .chat: chat.chatFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
        case .spaces: spaces.spacesFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
        case .settings: "arrow.up.left.and.arrow.down.right"
        }
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
