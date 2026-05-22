import Foundation
import Supabase
import UniformTypeIdentifiers

/// Isolated chat state for a dedicated pop-out window (does not disturb IDE panel selection).
@MainActor
final class ChatChannelSession: ObservableObject {
    let channel: ChatChannel
    let workspaceId: UUID
    let permissions: ChatWorkspacePermissions

    @Published var messages: [ChatMessage] = []
    @Published var reactions: [UUID: [ChatReactionSummary]] = [:]
    @Published var links: [UUID: [ChatMessageLink]] = [:]
    @Published var pinnedItems: [ChatPinnedItem] = []
    @Published var threadCounts: [UUID: Int] = [:]
    @Published var composerText = ""
    @Published var threadMessages: [ChatMessage] = []
    @Published var threadComposerText = ""
    @Published var activeThreadParent: ChatMessage?
    @Published var showThreadPanel = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uploadProgress: Double?
    @Published var typingLabel: String?
    @Published var editingMessageId: UUID?
    @Published var voiceTranscripts: [UUID: String] = [:]

    let profiles: [UUID: Profile]
    let presence: [UUID: ChatPresence]
    let currentUserId: UUID?

    private let service: ChatService
    private var typingTask: Task<Void, Never>?
    private var typingBroadcast: ChatTypingBroadcaster?

    init(channel: ChatChannel, auth: AuthViewModel, shared: ChatViewModel) {
        self.channel = channel
        workspaceId = channel.workspaceId
        permissions = shared.permissions
        profiles = shared.profiles
        presence = shared.presence
        currentUserId = shared.currentUserId
        service = ChatService(client: auth.client)
        typingBroadcast = ChatTypingBroadcaster(client: auth.client, workspaceId: channel.workspaceId)
        if let draft = service.localStore().loadDraft(channelId: channel.id) {
            composerText = draft.body
        }
        Task { await load() }
        let channelId = channel.id
        Task { [weak self] in
            await self?.typingBroadcast?.configureHandlers(
                onTyping: { cid, uid, name in
                    Task { @MainActor in
                        guard let self, self.channel.id == cid, uid != self.currentUserId else { return }
                        self.typingLabel = "\(name) is typing…"
                    }
                },
                onStop: { cid, _ in
                    Task { @MainActor in
                        guard let self, self.channel.id == cid else { return }
                        self.typingLabel = nil
                    }
                }
            )
            await self?.typingBroadcast?.subscribe(channelId: channelId)
        }
    }

    var mainChannelMessages: [ChatMessage] {
        messages.filter { $0.threadParentId == nil }
    }

    func displayName(for userId: UUID) -> String {
        if userId == currentUserId { return "You" }
        return profiles[userId]?.displayName ?? profiles[userId]?.email ?? "Member"
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        let cached = service.cachedMessages(channelId: channel.id)
        if !cached.isEmpty { messages = cached.filter { $0.threadParentId == nil } }
        do {
            messages = try await service.fetchMainChannelMessages(channelId: channel.id, workspaceId: workspaceId)
            await refreshExtras()
        } catch {
            if messages.isEmpty { errorMessage = error.localizedDescription }
        }
    }

    func refreshExtras() async {
        let ids = messages.map(\.id)
        if let map = try? await loadReactionMap(messageIds: ids) { reactions = map }
        if let fetched = try? await service.fetchLinks(messageIds: ids) {
            links = Dictionary(grouping: fetched, by: \.messageId)
        }
        if let pins = try? await service.fetchPinned(channelId: channel.id, workspaceId: workspaceId) {
            pinnedItems = pins
        }
        let allMessages = (try? await service.fetchMessages(channelId: channel.id, workspaceId: workspaceId)) ?? messages
        threadCounts = countThreads(in: allMessages)
    }

    private func loadReactionMap(messageIds: [UUID]) async throws -> [UUID: [ChatReactionSummary]] {
        let rows = try await service.fetchReactions(workspaceId: workspaceId, messageIds: messageIds)
        var map: [UUID: [ChatReactionSummary]] = [:]
        for (msgId, list) in Dictionary(grouping: rows, by: \.messageId) {
            let byEmoji = Dictionary(grouping: list, by: \.emoji)
            map[msgId] = byEmoji.map { emoji, rx in
                ChatReactionSummary(emoji: emoji, count: rx.count, userIds: rx.map(\.userId), includesMe: rx.contains { $0.userId == currentUserId })
            }.sorted { $0.count > $1.count }
        }
        return map
    }

    private func countThreads(in all: [ChatMessage]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for msg in all where msg.threadParentId != nil {
            counts[msg.threadParentId!, default: 0] += 1
        }
        return counts
    }

    func editMessage(_ message: ChatMessage, newBody: String) async {
        guard permissions.canEditMessages,
              message.userId == currentUserId else { return }
        do {
            let updated = try await service.editMessage(messageId: message.id, workspaceId: workspaceId, body: newBody)
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                messages[i] = updated
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteMessage(_ message: ChatMessage) async {
        guard permissions.canDeleteMessages else { return }
        do {
            try await service.deleteMessage(messageId: message.id, workspaceId: workspaceId)
            applyMessageDelete(message.id)
        } catch { errorMessage = error.localizedDescription }
    }

    func sendMessage() async {
        guard let userId = currentUserId else { return }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        composerText = ""
        await typingBroadcast?.stopTyping(channelId: channel.id, userId: userId, displayName: displayName(for: userId))
        do {
            let sent = try await service.sendMessageExtended(
                workspaceId: workspaceId,
                channelId: channel.id,
                userId: userId,
                body: text
            )
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
            }
            service.localStore().saveDraft(ChatDraft(channelId: channel.id, body: "", updatedAt: Date()))
            await refreshExtras()
        } catch {
            errorMessage = error.localizedDescription
            composerText = text
        }
    }

    func composerChanged() {
        service.localStore().saveDraft(ChatDraft(channelId: channel.id, body: composerText, updatedAt: Date()))
        guard let userId = currentUserId else { return }
        typingTask?.cancel()
        typingTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await typingBroadcast?.sendTyping(
                channelId: channel.id,
                userId: userId,
                displayName: displayName(for: userId)
            )
        }
    }

    func mergeIncoming(_ message: ChatMessage) {
        guard message.channelId == channel.id else { return }
        if let parent = message.threadParentId {
            if activeThreadParent?.id == parent, !threadMessages.contains(where: { $0.id == message.id }) {
                threadMessages.append(message)
            }
            threadCounts[parent, default: 0] += 1
            return
        }
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
        }
        Task { await refreshExtras() }
    }

    func applyMessageUpdate(_ message: ChatMessage) {
        if let i = messages.firstIndex(where: { $0.id == message.id }) { messages[i] = message }
        if let i = threadMessages.firstIndex(where: { $0.id == message.id }) { threadMessages[i] = message }
    }

    func applyMessageDelete(_ messageId: UUID) {
        if let i = messages.firstIndex(where: { $0.id == messageId }) {
            var m = messages[i]
            m.isDeleted = true
            m.body = nil
            messages[i] = m
        }
    }

    func toggleReaction(messageId: UUID, emoji: String) async {
        guard let userId = currentUserId else { return }
        _ = try? await service.toggleReaction(workspaceId: workspaceId, messageId: messageId, userId: userId, emoji: emoji)
        await refreshExtras()
    }

    func openThread(_ message: ChatMessage) async {
        activeThreadParent = message
        showThreadPanel = true
        threadMessages = (try? await service.fetchThreadReplies(parentId: message.id, workspaceId: workspaceId)) ?? []
    }

    func sendThreadReply() async {
        guard let parent = activeThreadParent, let userId = currentUserId else { return }
        let text = threadComposerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            let sent = try await service.sendMessageExtended(
                workspaceId: workspaceId,
                channelId: channel.id,
                userId: userId,
                body: text,
                threadParentId: parent.id
            )
            threadMessages.append(sent)
            threadComposerText = ""
            threadCounts[parent.id, default: 0] += 1
        } catch { errorMessage = error.localizedDescription }
    }

    func sendVoiceNote(url: URL, durationMs: Int, waveform: [Double]) async {
        guard permissions.canUseVoiceNotes, let userId = currentUserId else { return }
        do {
            let data = try Data(contentsOf: url)
            let fileName = "voice-\(UUID().uuidString).m4a"
            let uploaded = try await service.uploadChatFile(
                workspaceId: workspaceId,
                userId: userId,
                fileName: fileName,
                mimeType: "audio/mp4",
                data: data
            )
            let attachment = ChatAttachment(
                type: "voice",
                url: uploaded.publicURL.absoluteString,
                name: fileName,
                size: data.count,
                voiceNoteDurationMs: durationMs
            )
            let msg = try await service.sendMessageExtended(
                workspaceId: workspaceId,
                channelId: channel.id,
                userId: userId,
                body: nil,
                attachments: [attachment]
            )
            _ = try await service.saveVoiceTranscript(
                workspaceId: workspaceId,
                messageId: msg.id,
                storagePath: uploaded.fileRecord.path,
                durationMs: durationMs,
                waveform: waveform
            )
            voiceTranscripts[msg.id] = ChatAIService.mockTranscribeVoice(durationMs: durationMs)
            messages.append(msg)
            await refreshExtras()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadFile(from url: URL) async {
        guard permissions.canUploadFiles, let userId = currentUserId else { return }
        uploadProgress = 0.1
        do {
            let data = try Data(contentsOf: url)
            let name = url.lastPathComponent
            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            let result = try await service.uploadChatFile(
                workspaceId: workspaceId,
                userId: userId,
                fileName: name,
                mimeType: mime,
                data: data
            )
            uploadProgress = 0.7
            let attachment = ChatAttachment(
                type: mime.hasPrefix("image/") ? "image" : "file",
                url: result.publicURL.absoluteString,
                name: name,
                size: data.count
            )
            let msg = try await service.sendMessageExtended(
                workspaceId: workspaceId,
                channelId: channel.id,
                userId: userId,
                body: "Shared \(name)",
                attachments: [attachment]
            )
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
            uploadProgress = 1
            try? await Task.sleep(nanoseconds: 300_000_000)
            uploadProgress = nil
            await refreshExtras()
        } catch {
            uploadProgress = nil
            errorMessage = error.localizedDescription
        }
    }

    func teardown() {
        typingTask?.cancel()
        Task { await typingBroadcast?.unsubscribe() }
    }
}
