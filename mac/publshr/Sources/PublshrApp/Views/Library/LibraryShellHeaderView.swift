import SwiftUI

/// Per-column titlebar band — used only when `ShellColumnChromeStack(showsTitlebar: true)`.
/// The live shell uses `ShellUnifiedTitlebar`; these rows are placeholders for legacy/pop-out layouts.
enum ShellColumnHeaderKind {
    /// Left column: traffic-light inset; back/forward hidden when bar menu is collapsed to icon rail.
    case trafficLeading(module: Binding<AppModule>, compact: Bool = false)
    case secondaryChrome
    case chatSubmenu
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
        case .trafficLeading:
            Color.clear.frame(height: TrafficLightLayoutStore.shared.rowHeight)
        case .secondaryChrome, .chatSubmenu:
            Color.clear.frame(height: TrafficLightLayoutStore.shared.rowHeight)
        case .editorTrailing:
            Color.clear.frame(height: TrafficLightLayoutStore.shared.rowHeight)
        }
    }
}

/// Stacks optional titlebar band above column content.
struct ShellColumnChromeStack<Content: View>: View {
    var showsTitlebar: Bool = true
    var headerKind: ShellColumnHeaderKind?
    var appliesSidebarChrome: Bool = false
    var appliesPrimaryBarGlass: Bool = false
    @ViewBuilder var content: () -> Content

    init(
        showsTitlebar: Bool = true,
        headerKind: ShellColumnHeaderKind? = nil,
        appliesSidebarChrome: Bool = false,
        appliesPrimaryBarGlass: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showsTitlebar = showsTitlebar
        self.headerKind = headerKind
        self.appliesSidebarChrome = appliesSidebarChrome
        self.appliesPrimaryBarGlass = appliesPrimaryBarGlass
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsTitlebar, let headerKind {
                LibraryShellHeaderView(kind: headerKind)
            }
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
