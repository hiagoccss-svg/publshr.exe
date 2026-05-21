import Foundation
import AppKit
import UniformTypeIdentifiers

extension ChatViewModel {
    // MARK: - Phase 2 state (attached to main VM via extension helpers)

    func loadChannelExtras() async {
        guard let service, let workspace, let channel = selectedChannel else { return }
        let ids = messages.map(\.id)
        do {
            reactions = try await loadReactionMap(service: service, workspaceId: workspace.id, messageIds: ids)
            links = Dictionary(grouping: try await service.fetchLinks(messageIds: ids), by: \.messageId)
            pinnedItems = try await service.fetchPinned(channelId: channel.id, workspaceId: workspace.id)
            threadCounts = countThreads(in: messages)
        } catch {
            // keep cached
        }
    }

    func loadReactionMap(service: ChatService, workspaceId: UUID, messageIds: [UUID]) async throws -> [UUID: [ChatReactionSummary]] {
        let rows = try await service.fetchReactions(workspaceId: workspaceId, messageIds: messageIds)
        var map: [UUID: [ChatReactionSummary]] = [:]
        let grouped = Dictionary(grouping: rows, by: \.messageId)
        for (msgId, list) in grouped {
            let byEmoji = Dictionary(grouping: list, by: \.emoji)
            map[msgId] = byEmoji.map { emoji, reactions in
                ChatReactionSummary(
                    emoji: emoji,
                    count: reactions.count,
                    userIds: reactions.map(\.userId),
                    includesMe: reactions.contains { $0.userId == currentUserId }
                )
            }.sorted { $0.count > $1.count }
        }
        return map
    }

    func countThreads(in all: [ChatMessage]) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for msg in all {
            if let parent = msg.threadParentId {
                counts[parent, default: 0] += 1
            }
        }
        return counts
    }

    var mainChannelMessages: [ChatMessage] {
        messages.filter { $0.threadParentId == nil }
    }

    // MARK: - Edit / delete

    func editMessage(_ message: ChatMessage, newBody: String) async {
        guard permissions.canEditMessages,
              message.userId == currentUserId,
              let service, let workspace else { return }
        do {
            let updated = try await service.editMessage(messageId: message.id, workspaceId: workspace.id, body: newBody)
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                messages[i] = updated
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func deleteMessage(_ message: ChatMessage) async {
        guard permissions.canDeleteMessages,
              let service, let workspace else { return }
        let canDelete = message.userId == currentUserId || permissions.canDeleteMessages
        guard canDelete else { return }
        do {
            try await service.deleteMessage(messageId: message.id, workspaceId: workspace.id)
            if let i = messages.firstIndex(where: { $0.id == message.id }) {
                var m = messages[i]
                m.isDeleted = true
                m.body = nil
                messages[i] = m
            }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Reactions

    func toggleReaction(messageId: UUID, emoji: String) async {
        guard let service, let workspace, let userId = currentUserId else { return }
        do {
            _ = try await service.toggleReaction(
                workspaceId: workspace.id,
                messageId: messageId,
                userId: userId,
                emoji: emoji
            )
            await loadChannelExtras()
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Threads

    func openThread(for message: ChatMessage) async {
        activeThreadParent = message
        showThreadPanel = true
        guard let service, let workspace else { return }
        do {
            threadMessages = try await service.fetchThreadReplies(parentId: message.id, workspaceId: workspace.id)
        } catch {
            threadMessages = messages.filter { $0.threadParentId == message.id }
        }
    }

    func closeThread() {
        showThreadPanel = false
        activeThreadParent = nil
        threadMessages = []
    }

    func sendThreadReply() async {
        guard let parent = activeThreadParent,
              let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        let text = threadComposerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            let sent = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: text,
                threadParentId: parent.id
            )
            threadMessages.append(sent)
            threadComposerText = ""
            threadCounts[parent.id, default: 0] += 1
            if !messages.contains(where: { $0.id == sent.id }) {
                messages.append(sent)
            }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Pins

    func pinMessage(_ message: ChatMessage) async {
        guard permissions.canPinMessages,
              let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        do {
            let item = try await service.pinMessage(
                workspaceId: workspace.id,
                channelId: channel.id,
                messageId: message.id,
                userId: userId
            )
            pinnedItems.append(item)
        } catch { errorMessage = error.localizedDescription }
    }

    func unpinItem(_ item: ChatPinnedItem) async {
        guard let service else { return }
        try? await service.unpinItem(itemId: item.id)
        pinnedItems.removeAll { $0.id == item.id }
    }

    // MARK: - Files

    func uploadFile(from url: URL) async {
        guard permissions.canUploadFiles,
              let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        uploadProgress = 0.1
        do {
            let data = try Data(contentsOf: url)
            let name = url.lastPathComponent
            let mime = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
            let result = try await service.uploadChatFile(
                workspaceId: workspace.id,
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
            let body = "Shared \(name)"
            let msg = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: body,
                attachments: [attachment]
            )
            messages.append(msg)
            uploadProgress = 1
            try? await Task.sleep(nanoseconds: 300_000_000)
            uploadProgress = nil
            await loadChannelExtras()
        } catch {
            uploadProgress = nil
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Planner share

    func sharePlannerTask(_ task: PlannerTask) async {
        guard let service, let workspace, let channel = selectedChannel, let userId = currentUserId else { return }
        let preview = ChatLinkPreview(
            title: task.title,
            status: task.status,
            dueDate: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            owner: task.assigneeId.flatMap { displayName(for: $0) }
        )
        let body = "Shared planner item: \(task.title)"
        do {
            let msg = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: body
            )
            _ = try await service.attachLink(
                workspaceId: workspace.id,
                messageId: msg.id,
                linkType: .task,
                linkId: task.id,
                preview: preview
            )
            messages.append(msg)
            await loadChannelExtras()
        } catch { errorMessage = error.localizedDescription }
    }

    func loadPlannerTasks() async {
        guard let service, let workspace else { return }
        plannerTasks = (try? await service.fetchTasks(workspaceId: workspace.id)) ?? []
    }

    // MARK: - Voice

    func sendVoiceNote(url: URL, durationMs: Int, waveform: [Double]) async {
        guard permissions.canUseVoiceNotes,
              let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        do {
            let data = try Data(contentsOf: url)
            let fileName = "voice-\(UUID().uuidString).m4a"
            let uploaded = try await service.uploadChatFile(
                workspaceId: workspace.id,
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
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: nil,
                attachments: [attachment]
            )
            _ = try await service.saveVoiceTranscript(
                workspaceId: workspace.id,
                messageId: msg.id,
                storagePath: uploaded.fileRecord.path,
                durationMs: durationMs,
                waveform: waveform
            )
            let transcript = ChatAIService.mockTranscribeVoice(durationMs: durationMs)
            if let vt = try? await service.fetchVoiceTranscript(messageId: msg.id) {
                try? await service.updateTranscript(id: vt.id, transcript: transcript, status: .ready)
                voiceTranscripts[msg.id] = transcript
            }
            messages.append(msg)
            await loadChannelExtras()
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Search

    func runGlobalSearch() async {
        let q = globalSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { searchResults = []; return }
        var hits: [ChatSearchHit] = []
        if let service, let workspace, !isOffline {
            if let remote = try? await service.searchWorkspace(workspaceId: workspace.id, query: q) {
                for m in remote.messages {
                    hits.append(ChatSearchHit(
                        id: "msg-\(m.id.uuidString)",
                        kind: .message,
                        title: m.body ?? "",
                        subtitle: m.channel_name ?? "Channel",
                        channelId: m.channel_id,
                        messageId: m.id,
                        createdAt: nil
                    ))
                }
                for t in remote.tasks {
                    hits.append(ChatSearchHit(
                        id: "task-\(t.id.uuidString)",
                        kind: .task,
                        title: t.title,
                        subtitle: t.status ?? "task",
                        channelId: nil,
                        messageId: nil,
                        createdAt: nil
                    ))
                }
            }
        }
        let local = service?.localStore().searchMessages(query: q) ?? []
        for row in local {
            hits.append(ChatSearchHit(
                id: "local-\(row.messageId)",
                kind: .message,
                title: row.snippet,
                subtitle: row.channelName,
                channelId: row.channelId,
                messageId: UUID(uuidString: row.messageId),
                createdAt: nil
            ))
        }
        searchResults = hits
    }

    // MARK: - AI

    func runAISummary(unreadOnly: Bool = false) async {
        isAILoading = true
        defer { isAILoading = false }
        let pool: [ChatMessage]
        if unreadOnly {
            pool = messages.filter { $0.threadParentId == nil }
        } else if showThreadPanel, let parent = activeThreadParent {
            aiResult = ChatAIService.summarizeThread(root: parent, replies: threadMessages, profiles: profiles)
            return
        } else {
            pool = mainChannelMessages
        }
        aiResult = ChatAIService.summarizeMessages(pool, profiles: profiles)
    }

    func applySuggestedReply() {
        composerText = ChatAIService.suggestReply(to: messages)
    }

    // MARK: - Read receipts

    func markMessagesSeen() async {
        guard permissions.readReceiptsEnabled,
              let service, let workspace, let userId = currentUserId else { return }
        for msg in messages.suffix(5) where msg.userId != userId {
            try? await service.markSeen(workspaceId: workspace.id, messageId: msg.id, userId: userId)
        }
    }

    // MARK: - Multi-window

    func popOutCurrentChannel(auth: AuthViewModel) {
        guard let channel = selectedChannel else { return }
        ChatWindowManager.shared.openChannel(channel, chat: self, auth: auth)
    }

    // MARK: - Permissions persistence

    func savePermissionsToWorkspace() async {
        guard var ws = workspace else { return }
        var chatSettings: [String: JSONValue] = [:]
        chatSettings["can_create_channels"] = .bool(permissions.canCreateChannels)
        chatSettings["can_dm"] = .bool(permissions.canDM)
        chatSettings["can_use_voice_notes"] = .bool(permissions.canUseVoiceNotes)
        chatSettings["read_receipts_enabled"] = .bool(permissions.readReceiptsEnabled)
        chatSettings["can_upload_files"] = .bool(permissions.canUploadFiles)
        chatSettings["can_pin_messages"] = .bool(permissions.canPinMessages)
        chatSettings["can_export_chats"] = .bool(permissions.canExportChats)
        var settings = ws.settings ?? [:]
        settings["chat"] = .object(chatSettings)
        ws.settings = settings
        workspace = ws
    }
}
