import SwiftUI

struct ChatPinnedPanelView: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pinned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            if chat.pinnedItems.isEmpty {
                Text("No pinned items")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 12)
            } else {
                ForEach(chat.pinnedItems) { item in
                    HStack {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundDim)
                        Text(item.note ?? "Pinned message")
                            .font(.system(size: 11))
                            .lineLimit(2)
                        Spacer()
                        Button {
                            Task { await chat.unpinItem(item) }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CursorTheme.panelBackground.opacity(0.5))
    }
}
