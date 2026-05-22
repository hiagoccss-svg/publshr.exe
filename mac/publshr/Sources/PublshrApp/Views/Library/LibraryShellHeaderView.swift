import SwiftUI

/// Per-column titlebar band — background matches the column below; no full-width separator.
enum ShellColumnHeaderKind {
    /// Left column: empty band; reserves macOS traffic-light leading inset only.
    case primaryLeading
    /// Middle submenu column: empty band matching sidebar chrome.
    case secondaryChrome
    /// Right workspace column: context title + search / command / profile.
    case editor(
        title: String,
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
            .background { headerBackground }
    }

    @ViewBuilder
    private var headerBackground: some View {
        switch kind {
        case .primaryLeading:
            GlassPrimaryBarChrome()
        case .secondaryChrome:
            CursorMacShellDesign.columnChromeBackground
        case .editor:
            CursorMacShellDesign.editorColumnBackground
        }
    }

    @ViewBuilder
    private var rowContent: some View {
        switch kind {
        case .primaryLeading:
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: AppWindowChromeMetrics.trafficLightLeadingInset)
                Spacer(minLength: 0)
            }

        case .secondaryChrome:
            Color.clear
                .frame(maxWidth: .infinity)

        case .editor(let title, let module, let showCommandPalette, let showNotificationsPanel):
            HStack(alignment: .center, spacing: 12) {
                Spacer(minLength: 8)

                Text(title)
                    .font(CursorMacShellDesign.centerTitleFont)
                    .foregroundStyle(CursorMacShellDesign.centerTitleColor)
                    .lineLimit(1)

                Spacer(minLength: 8)

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
            content
                .background(CursorMacShellDesign.columnChromeBackground)
                .cursorColumnDividerTrailing()
        } else {
            content
        }
    }
}
