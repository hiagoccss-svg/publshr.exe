import SwiftUI

/// Per-column titlebar band — background matches the column below; no full-width separator.
enum ShellColumnHeaderKind {
    /// Left column: traffic-light inset + sidebar / back / forward.
    case trafficLeading(module: Binding<AppModule>)
    /// Middle submenu column: empty band matching sidebar chrome.
    case secondaryChrome
    /// Chat submenu: search in the titlebar row (ClickUp).
    case chatSubmenu
    /// Right column: profile, notifications, command only (editor gutter color).
    case editorTrailing(
        module: Binding<AppModule>,
        showCommandPalette: Binding<Bool>,
        showNotificationsPanel: Binding<Bool>
    )
}

struct LibraryShellHeaderView: View {
    @EnvironmentObject private var chat: ChatViewModel
    let kind: ShellColumnHeaderKind

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        rowContent
            .frame(height: rowHeight, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppWindowChromeMetrics.trafficLightVerticalAlignPadding)
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
            HStack(alignment: .center, spacing: CursorMacShellDesign.titlebarActionSpacing) {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                ShellTrafficLeadingActions(module: module)
                Spacer(minLength: 0)
            }
            .padding(.trailing, 8)
            .frame(maxHeight: .infinity, alignment: .center)

        case .secondaryChrome:
            Color.clear
                .frame(maxWidth: .infinity)

        case .chatSubmenu:
            ChatSidebarTitlebarChrome(chat: chat)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        case .editorTrailing(let module, let showCommandPalette, let showNotificationsPanel):
            HStack(alignment: .center, spacing: 0) {
                Spacer(minLength: 0)
                TitlebarChromeActionBar(
                    module: module,
                    showCommandPalette: showCommandPalette,
                    showNotificationsPanel: showNotificationsPanel,
                    placement: .trailing
                )
            }
            .padding(.trailing, 14)
            .frame(maxHeight: .infinity, alignment: .center)
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
