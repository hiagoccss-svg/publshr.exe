import SwiftUI

struct ChatSearchSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Search messages, tasks, files…", text: $chat.globalSearchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await chat.runGlobalSearch() } }
                Button("Search") { Task { await chat.runGlobalSearch() } }
            }
            .padding()

            List(chat.searchResults) { hit in
                Button {
                    if let cid = hit.channelId, let ch = (chat.channels + chat.directMessages).first(where: { $0.id == cid }) {
                        chat.selectChannel(ch)
                        dismiss()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hit.title)
                            .font(.system(size: 13))
                            .lineLimit(2)
                        Text(hit.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 480, height: 420)
    }
}
