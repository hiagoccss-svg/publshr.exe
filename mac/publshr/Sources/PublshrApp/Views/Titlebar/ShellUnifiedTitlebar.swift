import SwiftUI

/// One full-width titlebar row — column bands match the shell below; controls share one baseline (Cursor Mac).
struct ShellUnifiedTitlebar: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    @Binding var module: AppModule
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool

    var barColumnWidth: CGFloat
    var submenuColumnWidth: CGFloat
    var submenuHidden: Bool

    private var titlebarTopPadding: CGFloat {
        min(layout.titlebarTopPadding, AppWindowChromeMetrics.maxTitlebarTopPadding)
    }

    private var titlebarBandHeight: CGFloat {
        titlebarTopPadding + layout.rowHeight
    }

    private var barColumnCompact: Bool {
        !tabStore.barMenuExpanded
            || barColumnWidth <= LibraryGlassDesign.barMenuCollapsedWidth + AppWindowChromeMetrics.controlSize
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingBand
                .frame(width: barColumnWidth, alignment: .leading)

            if !submenuHidden {
                ShellColumnVerticalRule()
                submenuBand
                    .frame(width: submenuColumnWidth, alignment: .leading)
            }

            ShellColumnVerticalRule()
            editorBand
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: layout.rowHeight, alignment: .center)
        .padding(.top, titlebarTopPadding)
        .frame(height: titlebarBandHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(TrafficLightLayoutRefreshView().frame(width: 0, height: 0))
    }

    // MARK: - Column 1 (traffic reserve + shell controls)

    private var leadingBand: some View {
        let compact = !tabStore.barMenuExpanded || barColumnCompact
        let trafficSpacer = compact
            ? CGFloat(0)
            : min(layout.leadingInset, max(0, barColumnWidth - AppWindowChromeMetrics.controlSize))

        return TitlebarToolbarRow(trailingPadding: 6) {
            Color.clear
                .frame(width: trafficSpacer)
                .accessibilityHidden(true)
            ShellTrafficLeadingActions(
                module: $module,
                compact: compact,
                submenuHidden: submenuHidden
            )
        }
        .frame(height: layout.rowHeight)
        .clipped()
        .background { GlassPrimaryBarChrome() }
    }

    // MARK: - Column 2 (search — flat, no boxed field)

    @ViewBuilder
    private var submenuBand: some View {
        UniversalSubmenuTitlebarChrome(module: module, chat: chat, spaces: spaces)
            .padding(.horizontal, 10)
            .frame(height: layout.rowHeight)
            .background { GlassSubmenuChrome() }
    }

    // MARK: - Column 3 (channel / actions)

    @ViewBuilder
    private var editorBand: some View {
        Group {
            if module == .chat {
                ChatEditorToolbarContent(
                    showCommandPalette: $showCommandPalette,
                    showNotificationsPanel: $showNotificationsPanel
                )
                .padding(.leading, 10)
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
        .frame(height: layout.rowHeight)
        .background(CursorMacShellDesign.editorColumnBackground)
    }
}

/// Hairline between titlebar column bands (matches body column dividers).
struct ShellColumnVerticalRule: View {
    @ObservedObject private var layout = TrafficLightLayoutStore.shared

    var body: some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline.opacity(0.85))
            .frame(width: CursorMacShellDesign.columnDividerWidth, height: layout.rowHeight)
    }
}
