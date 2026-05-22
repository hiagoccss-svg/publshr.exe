import SwiftUI

/// Per-column titlebar band — background matches the column below; no full-width separator.
enum ShellColumnHeaderKind {
    /// Left column: traffic-light inset + sidebar / back / forward.
    case trafficLeading(module: Binding<AppModule>)
    /// Middle submenu column: empty band matching sidebar chrome.
    case secondaryChrome
    /// Right column: profile, notifications, command only (workspace gutter color).
    case editorTrailing(
        module: Binding<AppModule>,
        showCommandPalette: Binding<Bool>,
        showNotificationsPanel: Binding<Bool>
    )
}

struct LibraryShellHeaderView: View {
    let kind: ShellColumnHeaderKind

    private var rowHeight: CGFloat {
        AppWindowChromeMetrics.unifiedTitlebarRowHeight
    }

    var body: some View {
        rowContent
            .frame(height: rowHeight, alignment: .center)
            .frame(maxWidth: .infinity)
            .background(headerBackground)
    }

    private var headerBackground: Color {
        switch kind {
        case .trafficLeading, .secondaryChrome:
            return CursorMacShellDesign.columnChromeBackground
        case .editorTrailing:
            return CursorMacShellDesign.workspaceBackground
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        switch kind {
        case .trafficLeading(let module):
            HStack(alignment: .center, spacing: 10) {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                ShellTrafficLeadingActions(module: module)
                Spacer(minLength: 0)
            }
            .padding(.trailing, 8)

        case .secondaryChrome:
            Color.clear
                .frame(maxWidth: .infinity)

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
    var appliesSidebarChrome: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            LibraryShellHeaderView(kind: headerKind)
            content()
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .modifier(ShellColumnChromeBackground(appliesSidebarChrome: appliesSidebarChrome))
    }
}

private struct ShellColumnChromeBackground: ViewModifier {
    let appliesSidebarChrome: Bool

    func body(content: Content) -> some View {
        if appliesSidebarChrome {
            content
                .background(CursorMacShellDesign.columnChromeBackground)
                .cursorColumnDividerTrailing()
        } else {
            content
        }
    }
}
