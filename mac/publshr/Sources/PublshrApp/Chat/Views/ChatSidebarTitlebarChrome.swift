import SwiftUI

/// ClickUp-style top band for the chat submenu column — search in the titlebar row (no boxed field).
struct ChatSidebarTitlebarChrome: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        TitlebarToolbarRow(leadingPadding: 0, trailingPadding: 0) {
            TitlebarToolbarSlot {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: MacSystemChrome.fieldFontSize))
                .foregroundStyle(LibraryGlassDesign.ink)
                .frame(maxWidth: .infinity)
                .frame(height: AppWindowChromeMetrics.controlSize, alignment: .leading)
            if !chat.sidebarSearchQuery.isEmpty {
                TitlebarToolbarSlot {
                    Button {
                        chat.sidebarSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppWindowChromeMetrics.controlIconSize))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
