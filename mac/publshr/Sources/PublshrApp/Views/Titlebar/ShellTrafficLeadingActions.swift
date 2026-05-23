import SwiftUI

/// Controls immediately after the macOS traffic-light cluster (sidebar toggles + back / forward).
struct ShellTrafficLeadingActions: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    var compact: Bool = false
    var submenuHidden: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            if submenuHidden {
                TitlebarChromeIconButton(
                    systemName: tabStore.sidebarExpanded ? "sidebar.left" : "sidebar.right",
                    help: tabStore.sidebarExpanded ? "Hide submenu" : "Show submenu",
                    isActive: !tabStore.sidebarExpanded
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tabStore.sidebarExpanded.toggle()
                    }
                }
            }

            if compact || !tabStore.barMenuExpanded {
                TitlebarChromeIconButton(
                    systemName: "sidebar.leading",
                    help: "Expand main menu",
                    isActive: !tabStore.barMenuExpanded
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tabStore.barMenuExpanded = true
                    }
                }
            } else {
                TitlebarChromeIconButton(
                    systemName: "sidebar.trailing",
                    help: "Collapse to icon bar"
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tabStore.barMenuExpanded = false
                    }
                }
            }

            if !compact, tabStore.barMenuExpanded {
                TitlebarChromeIconButton(
                    systemName: "chevron.left",
                    help: TitlebarShortcutHint.tooltip("Back", shortcut: TitlebarShortcutHint.navigateBack),
                    isEnabled: canNavigateBack
                ) {
                    navigateBack()
                }

                TitlebarChromeIconButton(
                    systemName: "chevron.right",
                    help: TitlebarShortcutHint.tooltip("Forward", shortcut: TitlebarShortcutHint.navigateForward),
                    isEnabled: canNavigateForward
                ) {
                    navigateForward()
                }
            }
        }
    }

    private var canNavigateBack: Bool {
        switch module {
        case .chat: chat.canNavigateBack
        case .spaces, .whiteboard: spaces.canNavigateBack
        case .mediaMonitoring, .settings: false
        }
    }

    private var canNavigateForward: Bool {
        switch module {
        case .chat: chat.canNavigateForward
        case .spaces, .whiteboard: spaces.canNavigateForward
        case .mediaMonitoring, .settings: false
        }
    }

    private func navigateBack() {
        switch module {
        case .chat: chat.navigateBack()
        case .spaces, .whiteboard: Task { await spaces.navigateBack() }
        case .mediaMonitoring, .settings: break
        }
    }

    private func navigateForward() {
        switch module {
        case .chat: chat.navigateForward()
        case .spaces, .whiteboard: Task { await spaces.navigateForward() }
        case .mediaMonitoring, .settings: break
        }
    }
}
