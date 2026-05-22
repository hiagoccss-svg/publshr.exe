import SwiftUI

/// Column-2 titlebar band — search for the active module (Chat or Spaces).
struct UniversalSubmenuTitlebarChrome: View {
    var module: AppModule
    @ObservedObject var chat: ChatViewModel
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        Group {
            switch module {
            case .chat:
                ChatSidebarTitlebarChrome(chat: chat)
            case .spaces:
                SpacesSubmenuTitlebarChrome(spaces: spaces)
            case .settings:
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

/// Spaces universal submenu — search in the titlebar row (matches Chat).
struct SpacesSubmenuTitlebarChrome: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        TitlebarToolbarRow(leadingPadding: 0, trailingPadding: 0) {
            TitlebarToolbarSlot {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            TextField("Search spaces and tasks", text: $spaces.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: MacSystemChrome.fieldFontSize))
                .foregroundStyle(LibraryGlassDesign.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .frame(height: AppWindowChromeMetrics.controlSize)
            if !spaces.searchQuery.isEmpty {
                TitlebarToolbarSlot {
                    Button {
                        spaces.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppWindowChromeMetrics.controlIconSize))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
