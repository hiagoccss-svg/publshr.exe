import SwiftUI
import UniformTypeIdentifiers

struct ChatConversationView: View {
    @ObservedObject var chat: ChatViewModel
    @State private var showFileImporter = false
    @State private var showVoiceSheet = false
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 0) {
            mainColumn
            if chat.showThreadPanel {
                ChatThreadPanelView(chat: chat)
            }
        }
        .background(CursorTheme.chatBackground)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image, .pdf, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await chat.uploadFile(from: url) }
            }
        }
        .sheet(isPresented: $showVoiceSheet) {
            ChatVoiceRecorderSheet(chat: chat)
        }
        .sheet(isPresented: Binding(
            get: { chat.editingMessageId != nil },
            set: { if !$0 { chat.editingMessageId = nil } }
        )) {
            if let msgId = chat.editingMessageId {
                editSheet(messageId: msgId)
            }
        }
    }

    @ViewBuilder
    private var mainColumn: some View {
        Group {
            if let channel = chat.selectedChannel {
                conversation(channel)
            } else {
                VStack(spacing: 12) {
                    Text(chat.workspace?.name ?? "Chat")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    Text("Select a channel or direct message.")
                        .font(.system(size: 13))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func conversation(_ channel: ChatChannel) -> some View {
        VStack(spacing: 0) {
            if chat.showPinnedPanel && !chat.pinnedItems.isEmpty {
                ChatPinnedPanelView(chat: chat)
            }
            messageList
            if let progress = chat.uploadProgress {
                ProgressView(value: progress)
                    .padding(.horizontal, 12)
            }
            ChatComposerView(
                chat: chat,
                canSendVoiceNotes: chat.permissions.canUseVoiceNotes,
                onAttachFile: { attachFiles() },
                onVoiceNote: { showVoiceSheet = true }
            )
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
    }

    private var messageList: some View {
        Group {
            if chat.mainChannelMessages.isEmpty && !chat.isLoading {
                ChatEmptyStateView(
                    onNewMessage: {},
                    onCreateChannel: { Task { await chat.createChannel(name: "general") } }
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: CursorTheme.chatRowSpacing) {
                            ForEach(groupedMessages(), id: \.0) { day, msgs in
                                dayDivider(day)
                                ForEach(msgs) { msg in
                                    messageRow(msg, in: msgs)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: chat.mainChannelMessages.count) { _, _ in
                        if let last = chat.mainChannelMessages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private func messageRow(_ message: ChatMessage, in list: [ChatMessage]) -> some View {
        ChatMessageBubbleView(
            message: message,
            authorName: chat.displayName(for: message.userId),
            authorProfile: chat.profile(for: message.userId),
            presence: chat.presence(for: message.userId),
            isOwn: message.userId == chat.currentUserId,
            showAvatar: shouldShowAvatar(message, in: list),
            reactions: chat.reactions[message.id] ?? [],
            links: chat.links[message.id] ?? [],
            threadReplyCount: chat.threadCounts[message.id] ?? 0,
            voiceTranscript: chat.voiceTranscripts[message.id],
            onRetry: { Task { await chat.retryMessage(message) } },
            onReaction: { emoji in Task { await chat.toggleReaction(messageId: message.id, emoji: emoji) } },
            onThread: { Task { await chat.openThread(for: message) } },
            onPin: { Task { await chat.pinMessage(message) } },
            onEdit: { chat.editingMessageId = message.id; editText = message.body ?? "" },
            onDelete: { Task { await chat.deleteMessage(message) } }
        )
    }

    private func dayDivider(_ day: String) -> some View {
        HStack {
            Spacer()
            Text(day)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(CursorTheme.editorLineHighlight.opacity(0.5))
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func groupedMessages() -> [(String, [ChatMessage])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var groups: [String: [ChatMessage]] = [:]
        for msg in chat.mainChannelMessages {
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

    private func attachFiles() {
        guard chat.permissions.canUploadFiles else { return }
        let urls = FileAccessService.pickFiles(allowedTypes: [.image, .pdf, .data])
        guard let url = urls.first else { return }
        Task { await chat.uploadFile(from: url) }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard chat.permissions.canUploadFiles else { return false }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                Task { @MainActor in await chat.uploadFile(from: url) }
            }
            return true
        }
        return false
    }

    @ViewBuilder
    private func editSheet(messageId: UUID) -> some View {
        VStack(spacing: 12) {
            Text("Edit message")
                .font(.headline)
            TextField("Message", text: $editText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { chat.editingMessageId = nil }
                Button("Save") {
                    if let msg = chat.messages.first(where: { $0.id == messageId }) {
                        Task {
                            await chat.editMessage(msg, newBody: editText)
                            chat.editingMessageId = nil
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
