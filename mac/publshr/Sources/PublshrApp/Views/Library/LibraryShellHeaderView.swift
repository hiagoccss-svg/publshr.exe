import SwiftUI

/// Per-column titlebar band — background matches the column below; no full-width separator.
enum ShellColumnHeaderKind {
    /// Left column: traffic-light inset + sidebar / back / forward.
    case trafficLeading(module: Binding<AppModule>)
    /// Middle submenu column: empty band matching sidebar chrome.
    case secondaryChrome
    /// Chat submenu: search in the titlebar row (ClickUp).
    case chatSubmenu
    /// Right column: channel title + actions (chat) or profile cluster (spaces).
    case editorTrailing(
        module: Binding<AppModule>,
        showCommandPalette: Binding<Bool>,
        showNotificationsPanel: Binding<Bool>
    )
}

struct LibraryShellHeaderView: View {
    @EnvironmentObject private var chat: ChatViewModel
    let kind: ShellColumnHeaderKind

    var body: some View {
        rowContent
            .frame(maxWidth: .infinity)
            .background { headerBackground }
    }

    @ViewBuilder
    private var headerBackground: some View {
        switch kind {
        case .trafficLeading:
            GlassPrimaryBarChrome()
        case .secondaryChrome, .chatSubmenu:
            GlassSubmenuChrome()
        case .editorTrailing:
            CursorMacShellDesign.editorColumnBackground
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        switch kind {
        case .trafficLeading(let module):
            TitlebarToolbarRow(trailingPadding: 8) {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                ShellTrafficLeadingActions(module: module)
                Spacer(minLength: 0)
            }

        case .secondaryChrome:
            TitlebarToolbarRow {
                Color.clear
                    .frame(maxWidth: .infinity)
            }

        case .chatSubmenu:
            TitlebarToolbarRow(leadingPadding: 12, trailingPadding: 6) {
                ChatSidebarTitlebarChrome(chat: chat)
                Spacer(minLength: 0)
            }

        case .editorTrailing(let module, let showCommandPalette, let showNotificationsPanel):
            Group {
                if module.wrappedValue == .chat {
                    ChatEditorHeaderBar(showCommandPalette: showCommandPalette)
                } else {
                    TitlebarToolbarRow(trailingPadding: 14) {
                        Spacer(minLength: 0)
                        TitlebarChromeActionBar(
                            module: module,
                            showCommandPalette: showCommandPalette,
                            showNotificationsPanel: showNotificationsPanel,
                            placement: .trailing
                        )
                    }
                }
            }
        }
    }
}

/// Stacks a column header band above content with matching chrome background.
struct ShellColumnChromeStack<Content: View>: View {
    let headerKind: ShellColumnHeaderKind
    var appliesSidebarChrome: Bool = false
    var appliesPrimaryBarGlass: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            LibraryShellHeaderView(kind: headerKind)
            content()
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .modifier(ShellColumnChromeBackground(
            appliesSidebarChrome: appliesSidebarChrome,
            appliesPrimaryBarGlass: appliesPrimaryBarGlass
        ))
    }
}

private struct ShellColumnChromeBackground: ViewModifier {
    let appliesSidebarChrome: Bool
    let appliesPrimaryBarGlass: Bool

    func body(content: Content) -> some View {
        if appliesPrimaryBarGlass {
            content.glassPrimaryBar()
        } else if appliesSidebarChrome {
            content.glassSubmenu()
        } else {
            content
        }
    }
}
