import SwiftUI

/// ClickUp-style top band for the chat submenu column — search in the titlebar row (no boxed field).
struct ChatSidebarTitlebarChrome: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            TextField("Search channels and people", text: $chat.sidebarSearchQuery)
                .textFieldStyle(.plain)
                .font(ChatClickUpDesign.searchFont)
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
        .padding(.horizontal, 12)
        .padding(.trailing, 6)
    }
}
