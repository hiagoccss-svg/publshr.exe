import SwiftUI

struct ChatThreadPanelView: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Thread")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    chat.closeThread()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(CursorTheme.panelBackground)

            if let parent = chat.activeThreadParent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ChatMessageBubbleView(
                            message: parent,
                            authorName: chat.displayName(for: parent.userId),
                            authorProfile: chat.profile(for: parent.userId),
                            presence: chat.presence(for: parent.userId),
                            isOwn: parent.userId == chat.currentUserId,
                            showAvatar: true
                        )
                        Divider().opacity(0.35)
                        ForEach(chat.threadMessages) { msg in
                            ChatMessageBubbleView(
                                message: msg,
                                authorName: chat.displayName(for: msg.userId),
                                authorProfile: chat.profile(for: msg.userId),
                                presence: chat.presence(for: msg.userId),
                                isOwn: msg.userId == chat.currentUserId,
                                showAvatar: true
                            )
                        }
                    }
                    .padding(12)
                }
            }

            HStack(spacing: 8) {
                TextField("Reply in thread…", text: $chat.threadComposerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .lineLimit(1...4)
                Button {
                    Task { await chat.sendThreadReply() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(CursorTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(CursorTheme.panelBackground)
        }
        .frame(width: 280)
        .background(CursorTheme.chatBackground)
        .overlay(alignment: .leading) {
            Rectangle().fill(CursorTheme.borderSubtle.opacity(0.8)).frame(width: 1)
        }
    }
}
