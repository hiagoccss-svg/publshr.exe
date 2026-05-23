import SwiftUI

/// Per-column shell chrome — each column owns its titlebar band + body (Cursor Mac).
enum LibraryShellColumnLayout {
    static func titlebarBandHeight(layout: TrafficLightLayoutStore) -> CGFloat {
        let top = min(layout.titlebarTopPadding, AppWindowChromeMetrics.maxTitlebarTopPadding)
        return top + layout.rowHeight
    }

    static func titlebarTopPadding(layout: TrafficLightLayoutStore) -> CGFloat {
        min(layout.titlebarTopPadding, AppWindowChromeMetrics.maxTitlebarTopPadding)
    }

    static func trafficLeadingSpacer(width: CGFloat, layout: TrafficLightLayoutStore) -> CGFloat {
        min(layout.leadingInset, max(0, width - AppWindowChromeMetrics.controlSize))
    }
}

// MARK: - Column 1 (primary bar — traffic lights + modules)

struct LibraryShellBarColumn: View {
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    var width: CGFloat
    var submenuHidden: Bool
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        let topPad = LibraryShellColumnLayout.titlebarTopPadding(layout: layout)
        let bandH = LibraryShellColumnLayout.titlebarBandHeight(layout: layout)

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                GlassPrimaryBarChrome()
                VStack(spacing: 0) {
                    Color.clear.frame(height: topPad)
                    TitlebarToolbarRow(trailingPadding: 6) {
                        Color.clear
                            .frame(width: LibraryShellColumnLayout.trafficLeadingSpacer(width: width, layout: layout))
                            .accessibilityHidden(true)
                        ShellTrafficLeadingActions(
                            module: $module,
                            submenuHidden: submenuHidden
                        )
                    }
                    .frame(height: layout.rowHeight)
                }
            }
            .frame(width: width, height: bandH, alignment: .topLeading)

            LibraryBarMenuColumn(
                barWidth: width,
                module: $module,
                profilePresentation: $profilePresentation
            )
            .frame(maxWidth: width, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width, maxHeight: .infinity, alignment: .topLeading)
        .background { GlassPrimaryBarChrome() }
    }
}

// MARK: - Column 2 (universal submenu)

struct LibraryShellSubmenuColumn: View {
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    var width: CGFloat
    var module: AppModule
    @ObservedObject var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        let topPad = LibraryShellColumnLayout.titlebarTopPadding(layout: layout)
        let bandH = LibraryShellColumnLayout.titlebarBandHeight(layout: layout)

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                GlassSubmenuChrome()
                VStack(spacing: 0) {
                    Color.clear.frame(height: topPad)
                    UniversalSubmenuTitlebarChrome(module: module, chat: chat, spaces: spaces)
                        .padding(.horizontal, 12)
                        .frame(height: layout.rowHeight)
                }
            }
            .frame(width: width, height: bandH, alignment: .topLeading)

            AppSecondarySidebar(
                submenuWidth: width,
                module: module,
                chat: chat,
                spaces: spaces,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM
            )
            .frame(maxWidth: width, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: width, maxHeight: .infinity, alignment: .topLeading)
        .background { GlassSubmenuChrome() }
    }
}

// MARK: - Column 3 (editor — channel toolbar + module content)

struct LibraryShellEditorColumn<Content: View>: View {
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    @Binding var module: AppModule
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        let topPad = LibraryShellColumnLayout.titlebarTopPadding(layout: layout)
        let bandH = LibraryShellColumnLayout.titlebarBandHeight(layout: layout)

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                CursorMacShellDesign.editorColumnBackground
                VStack(spacing: 0) {
                    Color.clear.frame(height: topPad)
                    editorTitlebar
                        .frame(height: layout.rowHeight)
                }
            }
            .frame(maxWidth: .infinity, minHeight: bandH, maxHeight: bandH, alignment: .topLeading)

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    @ViewBuilder
    private var editorTitlebar: some View {
        if module == .chat {
            ChatEditorToolbarContent(
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel
            )
            .padding(.leading, 12)
            .padding(.trailing, 12)
        } else {
            TitlebarToolbarRow(trailingPadding: 12) {
                Spacer(minLength: 0)
                TitlebarChromeActionBar(
                    module: $module,
                    showCommandPalette: $showCommandPalette,
                    showNotificationsPanel: $showNotificationsPanel,
                    placement: .trailing
                )
            }
        }
    }
}

/// Full-height hairline between shell columns (body + titlebar).
struct ShellColumnFullHeightRule: View {
    var body: some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline.opacity(0.85))
            .frame(width: CursorMacShellDesign.columnDividerWidth)
            .frame(maxHeight: .infinity)
    }
}
