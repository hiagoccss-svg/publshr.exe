import SwiftUI

struct ChatSearchSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                TextField(searchPlaceholder, text: $chat.globalSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: MacSystemChrome.fieldFontSize))
                    .onSubmit { Task { await chat.runGlobalSearch() } }
                Button("Search") { Task { await chat.runGlobalSearch() } }
                    .buttonStyle(.borderless)
            }
            .macInlineTextField(background: MacSystemChrome.submenuFieldBackground())
            .padding(MacSystemChrome.sheetPadding)

            HStack(spacing: 6) {
                Image(systemName: chat.searchScopeChannelId == nil ? "building.2" : "number")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
                Text("Scope: \(chat.searchScopeLabel)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Spacer()
            }
            .padding(.horizontal, MacSystemChrome.sheetPadding)
            .padding(.bottom, 8)

            Divider().opacity(0.35)

            List(chat.searchResults) { hit in
                Button {
                    if let cid = hit.channelId, let ch = (chat.channels + chat.directMessages).first(where: { $0.id == cid }) {
                        chat.selectChannel(ch)
                        if let mid = hit.messageId {
                            chat.jumpToMessage(mid)
                        }
                        dismiss()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hit.title)
                            .font(.system(size: MacSystemChrome.fieldFontSize))
                            .lineLimit(2)
                        Text(hit.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.inset)
        }
        .frame(width: 480, height: 420)
        .macNativeSheetPresentation()
        .onAppear {
            if !chat.globalSearchQuery.isEmpty {
                Task { await chat.runGlobalSearch() }
            }
        }
    }

    private var searchPlaceholder: String {
        chat.searchScopeChannelId == nil
            ? "Search workspace messages and tasks…"
            : "Search in \(chat.searchScopeLabel)…"
    }
}
