import SwiftUI

/// One full-width titlebar row — traffic lights, shell controls, submenu search, and editor actions share a single centerline.
struct ShellUnifiedTitlebar: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    @Binding var module: AppModule
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    var submenuHidden: Bool

    private var submenuWidth: CGFloat { LibraryGlassDesign.sidebarWidthWide }

    private var titlebarBandHeight: CGFloat {
        layout.titlebarTopPadding + layout.rowHeight
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingBand
            if !submenuHidden {
                submenuBand
                    .frame(width: submenuWidth)
            }
            editorBand
                .frame(maxWidth: .infinity)
        }
        .frame(height: layout.rowHeight, alignment: .center)
        .padding(.top, layout.titlebarTopPadding)
        .frame(height: titlebarBandHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(TrafficLightLayoutRefreshView().frame(width: 0, height: 0))
    }

    // MARK: - Leading (traffic reserve + sidebar + back/forward)

    private var leadingBand: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            Color.clear
                .frame(width: layout.leadingInset)
                .accessibilityHidden(true)
            TitlebarChromeIconButton(
                systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                help: tabStore.sidebarExpanded
                    ? "Hide chat/spaces submenu"
                    : "Show chat/spaces submenu",
                isActive: !tabStore.sidebarExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.sidebarExpanded.toggle()
                }
            }
            ShellTrafficLeadingActions(
                module: $module,
                compact: !tabStore.barMenuExpanded
            )
        }
        .padding(.trailing, 4)
        .frame(minWidth: CursorMacShellDesign.barMenuIconRailWidth, alignment: .leading)
        .frame(height: layout.rowHeight)
        .background { GlassPrimaryBarChrome() }
    }

    // MARK: - Submenu (channel search)

    @ViewBuilder
    private var submenuBand: some View {
        Group {
            if module == .chat {
                ChatSidebarTitlebarChrome(chat: chat)
                    .padding(.horizontal, 12)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: layout.rowHeight)
        .background { GlassSubmenuChrome() }
    }

    // MARK: - Editor (channel chrome or spaces actions)

    @ViewBuilder
    private var editorBand: some View {
        Group {
            if module == .chat {
                ChatEditorToolbarContent(
                    showCommandPalette: $showCommandPalette,
                    showNotificationsPanel: $showNotificationsPanel
                )
                .padding(.leading, CursorMacShellDesign.editorHorizontalPadding)
                .padding(.trailing, 14)
            } else {
                HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
                    Spacer(minLength: 0)
                    TitlebarChromeActionBar(
                        module: $module,
                        showCommandPalette: $showCommandPalette,
                        showNotificationsPanel: $showNotificationsPanel,
                        placement: .trailing
                    )
                }
                .padding(.trailing, 14)
            }
        }
        .frame(height: layout.rowHeight)
        .background(CursorMacShellDesign.editorColumnBackground)
    }
}
