import SwiftUI

/// ClickUp-style top band for the chat submenu column — search in the titlebar row (no boxed field).
struct ChatSidebarTitlebarChrome: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: MacSystemChrome.fieldFontSize))
                .foregroundStyle(LibraryGlassDesign.ink)
            if !chat.sidebarSearchQuery.isEmpty {
                Button {
                    chat.sidebarSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .macInlineTextField(
            background: MacSystemChrome.submenuFieldBackground(),
            cornerRadius: MacSystemChrome.fieldCornerRadius
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
