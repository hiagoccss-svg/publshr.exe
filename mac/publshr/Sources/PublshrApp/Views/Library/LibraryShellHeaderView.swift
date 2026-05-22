import SwiftUI

/// Per-column titlebar band — background matches the column below; no full-width separator.
enum ShellColumnHeaderKind {
    /// Left column: traffic-light inset; back/forward hidden when bar menu is collapsed to icon rail.
    case trafficLeading(module: Binding<AppModule>, compact: Bool = false)
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
    /// When set, the header band matches a fixed shell column (prevents HStack equal-width stretch).
    var columnWidth: CGFloat?

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        rowContent
            .frame(height: rowHeight, alignment: .center)
            .frame(width: columnWidth, alignment: .leading)
            .frame(maxWidth: columnWidth == nil ? .infinity : columnWidth)
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
        case .trafficLeading(let module, let compact):
            HStack(alignment: .center, spacing: compact ? 0 : 10) {
                if !compact {
                    Color.clear
                        .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                }
                ShellTrafficLeadingActions(module: module, compact: compact)
                if !compact {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
            .padding(.trailing, compact ? 0 : 8)

        case .secondaryChrome:
            Color.clear
                .frame(width: columnWidth, height: 1)

        case .chatSubmenu:
            ChatSidebarTitlebarChrome(chat: chat)
                .frame(width: columnWidth, alignment: .leading)

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
        }
    }
}

/// Stacks a column header band above content with matching chrome background.
struct ShellColumnChromeStack<Content: View>: View {
    let headerKind: ShellColumnHeaderKind
    /// Locks column width in the shell `HStack` (nil = flexible editor column).
    var columnWidth: CGFloat?
    var appliesSidebarChrome: Bool = false
    var appliesPrimaryBarGlass: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            LibraryShellHeaderView(kind: headerKind, columnWidth: columnWidth)
            content()
                .frame(
                    maxWidth: columnWidth == nil ? .infinity : columnWidth,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        }
        .frame(width: columnWidth, alignment: .leading)
        .frame(minHeight: 0, maxHeight: .infinity)
        .fixedSize(horizontal: columnWidth != nil, vertical: false)
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
