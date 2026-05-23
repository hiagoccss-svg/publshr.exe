import SwiftUI

/// Controls immediately after the macOS traffic-light cluster (back / forward when the bar menu is expanded).
struct ShellTrafficLeadingActions: View {
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            if !compact {
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
