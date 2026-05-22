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
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundDim)
                            .padding(.top, 2)
                        Button {
                            if let mid = item.messageId {
                                chat.jumpToMessage(mid)
                            }
                        } label: {
                            Text(chat.pinnedPreview(for: item))
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.foreground)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
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
