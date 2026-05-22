import SwiftUI

struct ChatSearchSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                TextField("Search messages, tasks, files…", text: $chat.globalSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: MacSystemChrome.fieldFontSize))
                    .onSubmit { Task { await chat.runGlobalSearch() } }
                Button("Search") { Task { await chat.runGlobalSearch() } }
                    .buttonStyle(.borderless)
            }
            .macInlineTextField(background: MacSystemChrome.submenuFieldBackground())
            .padding(MacSystemChrome.sheetPadding)

            Divider().opacity(0.35)

            List(chat.searchResults) { hit in
                Button {
                    if let cid = hit.channelId, let ch = (chat.channels + chat.directMessages).first(where: { $0.id == cid }) {
                        chat.selectChannel(ch)
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
    }
}
