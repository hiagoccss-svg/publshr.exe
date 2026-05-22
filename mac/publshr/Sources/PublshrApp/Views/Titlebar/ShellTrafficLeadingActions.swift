import SwiftUI

/// Controls immediately after the macOS traffic-light cluster.
struct ShellTrafficLeadingActions: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            TitlebarChromeIconButton(
                systemName: tabStore.barMenuExpanded ? "sidebar.left" : "sidebar.right",
                help: tabStore.barMenuExpanded
                    ? "Collapse main menu to icon bar"
                    : "Expand main menu",
                isActive: !tabStore.barMenuExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tabStore.barMenuExpanded.toggle()
                }
            }

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

    private var canNavigateBack: Bool {
        switch module {
        case .chat: chat.canNavigateBack
        case .spaces: spaces.canNavigateBack
        case .settings: false
        }
    }

    private var canNavigateForward: Bool {
        switch module {
        case .chat: chat.canNavigateForward
        case .spaces: spaces.canNavigateForward
        case .settings: false
        }
    }

    private func navigateBack() {
        switch module {
        case .chat: chat.navigateBack()
        case .spaces: Task { await spaces.navigateBack() }
        case .settings: break
        }
    }

    private func navigateForward() {
        switch module {
        case .chat: chat.navigateForward()
        case .spaces: Task { await spaces.navigateForward() }
        case .settings: break
        }
    }
}
