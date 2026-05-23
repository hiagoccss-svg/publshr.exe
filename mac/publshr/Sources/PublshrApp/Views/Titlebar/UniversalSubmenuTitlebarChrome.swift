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
            case .spaces, .whiteboard:
                SpacesSubmenuTitlebarChrome(spaces: spaces)
            case .mediaMonitoring:
                MediaMonitoringSubmenuTitlebarChrome()
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
                .frame(maxWidth: .infinity)
                .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
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

/// Media Monitoring submenu — search in the titlebar row (matches Chat / Spaces).
struct MediaMonitoringSubmenuTitlebarChrome: View {
    @EnvironmentObject private var media: MediaMonitoringViewModel

    var body: some View {
        TitlebarToolbarRow(leadingPadding: 0, trailingPadding: 0) {
            TitlebarToolbarSlot {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            TextField("Search coverage and clips", text: $media.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: MacSystemChrome.fieldFontSize))
                .foregroundStyle(LibraryGlassDesign.ink)
                .frame(maxWidth: .infinity)
                .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
        }
    }
}
