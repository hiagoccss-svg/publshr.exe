import SwiftUI

/// Unified window chrome — one fixed-height row shared with macOS traffic lights (Cursor / VS Code style).
struct LibraryShellHeaderView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showNotificationsPanel: Bool
    /// When hosted in `NSTitlebarAccessoryViewController`, AppKit already offsets for traffic lights.
    var reservesTrafficLightLeadingInset: Bool = true

    /// Nudge row content to the traffic-light vertical center (tune per macOS release).
    private var titlebarVerticalPadding: CGFloat {
        reservesTrafficLightLeadingInset
            ? AppWindowChromeMetrics.trafficLightVerticalAlignPadding
            : 0
    }

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        titlebarRow
            .padding(.top, titlebarVerticalPadding)
            .frame(height: rowHeight, alignment: .center)
            .frame(maxWidth: .infinity)
            .background { AppWindowChromeBackground() }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CursorMacShellDesign.border)
                    .frame(height: 1)
            }
    }

    private var titlebarRow: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.rowSpacing) {
            if reservesTrafficLightLeadingInset {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
            }

            TitlebarChromeActionBar(
                spaces: spaces,
                module: $module,
                showNewChannel: $showNewChannel,
                showNewDM: $showNewDM,
                showCommandPalette: $showCommandPalette,
                showNotificationsPanel: $showNotificationsPanel,
                placement: .leading
            )

            tabStrip

            Spacer(minLength: 8)

        }
        .padding(.trailing, 12)
    }

    // MARK: - Tabs

    private var tabStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: CursorMacShellDesign.tabSpacing) {
                ForEach(tabStore.tabs) { tab in
                    ChromeDocumentTab(
                        title: tab.title,
                        isSelected: tabStore.selectedTabId == tab.id,
                        canClose: tabStore.tabs.count > 1,
                        onSelect: { selectTab(tab) },
                        onClose: { closeTab(tab) }
                    )
                }
                addTabButton
            }
        }
        .frame(maxWidth: 420)
    }

    private var addTabButton: some View {
        Menu {
            Section("Applications") {
                ForEach(AppModule.mainStrip) { app in
                    Button {
                        tabStore.openFromModule(app)
                        module = app
                        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
                    } label: {
                        Label(app.label, systemImage: app.systemImage)
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.documentTabHeight
                )
        }
        .menuStyle(.borderlessButton)
        .help("New tab")
    }

    // MARK: - Tab actions

    private func selectTab(_ tab: WorkspaceTab) {
        tabStore.selectTab(id: tab.id)
        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
    }

    private func closeTab(_ tab: WorkspaceTab) {
        tabStore.closeTab(id: tab.id)
        tabStore.applySelection(module: &module, chat: chat, spaces: spaces)
    }

}

// MARK: - Tab kind helpers

private extension WorkspaceTabKind {
    var isChatChannelOrDM: Bool {
        switch self {
        case .chatChannel, .chatDirectMessage: return true
        default: return false
        }
    }

    var isSpaceTab: Bool {
        if case .space = self { return true }
        return false
    }
}
