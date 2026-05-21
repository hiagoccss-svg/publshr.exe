import SwiftUI

struct ChatConversationView: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        Group {
            if let channel = chat.selectedChannel {
                conversation(channel)
            } else {
                VStack(spacing: 12) {
                    Text("Team Chat")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    Text("Select a channel or direct message.")
                        .font(.system(size: 13))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(CursorTheme.chatBackground)
    }

    @ViewBuilder
    private func conversation(_ channel: ChatChannel) -> some View {
        VStack(spacing: 0) {
            channelHeader(channel)

            if chat.messages.isEmpty && !chat.isLoading {
                ChatEmptyStateView(
                    onNewMessage: { /* composer ready */ },
                    onCreateChannel: { Task { await chat.createChannel(name: "general") } }
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(groupedMessages(), id: \.0) { day, msgs in
                                dayDivider(day)
                                ForEach(msgs) { msg in
                                    ChatMessageBubbleView(
                                        message: msg,
                                        authorName: chat.displayName(for: msg.userId),
                                        isOwn: msg.userId == chat.currentUserId,
                                        showAvatar: shouldShowAvatar(msg, in: msgs),
                                        onRetry: { Task { await chat.retryMessage(msg) } }
                                    )
                                    .id(msg.id)
                                }
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: chat.messages.count) { _, _ in
                        if let last = chat.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            ChatComposerView(
                chat: chat,
                canSendVoiceNotes: chat.permissions.canUseVoiceNotes
            )
        }
    }

    private func channelHeader(_ channel: ChatChannel) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
                if let desc = channel.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            if chat.isOffline {
                Label("Offline", systemImage: "wifi.slash")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            channelVisibilityBadge(channel.visibility)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(CursorTheme.panelBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private func channelVisibilityBadge(_ visibility: ChatChannelVisibility) -> some View {
        Text(visibility.rawValue.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 10))
            .foregroundStyle(CursorTheme.foregroundDim)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(CursorTheme.inputBackground)
            .clipShape(Capsule())
    }

    private func dayDivider(_ day: String) -> some View {
        HStack {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
            Text(day)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
        .padding(.vertical, 8)
    }

    private func groupedMessages() -> [(String, [ChatMessage])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var groups: [String: [ChatMessage]] = [:]
        for msg in chat.messages where !msg.isDeleted || msg.body != nil {
            let key = formatter.string(from: msg.createdAt)
            groups[key, default: []].append(msg)
        }
        return groups.sorted { $0.value.first?.createdAt ?? .distantPast < $1.value.first?.createdAt ?? .distantPast }
    }

    private func shouldShowAvatar(_ message: ChatMessage, in list: [ChatMessage]) -> Bool {
        guard let idx = list.firstIndex(where: { $0.id == message.id }) else { return true }
        if idx == 0 { return true }
        return list[idx - 1].userId != message.userId
    }
}
