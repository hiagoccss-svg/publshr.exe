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
                m.attachments = []
                messages[i] = m
            }
            if activeThreadParent?.id == message.id || threadMessages.contains(where: { $0.id == message.id }) {
                threadMessages.removeAll { $0.id == message.id }
            }
            voiceTranscripts.removeValue(forKey: message.id)
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

    // MARK: - Reply

    func beginReply(to message: ChatMessage) {
        replyingTo = message
    }

    func cancelReply() {
        replyingTo = nil
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
            let data = try FileAccessService.readData(from: url)
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
            let attachmentType: String = {
                if mime.hasPrefix("image/") { return "image" }
                if mime.hasPrefix("video/") { return "video" }
                return "file"
            }()
            let attachment = ChatAttachment(
                type: attachmentType,
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
                linkType: ChatLinkType.task,
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
            let data = try FileAccessService.readData(from: url)
            let fileName = "voice-\(UUID().uuidString).m4a"
            let localURL = try LocalVoiceNoteStore.saveRecording(
                from: url,
                workspaceId: workspace.id,
                channelId: channel.id
            )
            var playbackURL = localURL.absoluteString
            var storagePath = localURL.path
            if let uploaded = try? await service.uploadChatFile(
                workspaceId: workspace.id,
                userId: userId,
                fileName: fileName,
                mimeType: "audio/mp4",
                data: data
            ) {
                playbackURL = uploaded.publicURL.absoluteString
                storagePath = uploaded.fileRecord.path
            }
            let attachment = ChatAttachment(
                type: "voice",
                url: playbackURL,
                name: fileName,
                size: data.count,
                voiceNoteDurationMs: durationMs
            )
            let msg = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: Optional<String>.none,
                attachments: [attachment]
            )
            _ = try await service.saveVoiceTranscript(
                workspaceId: workspace.id,
                messageId: msg.id,
                storagePath: storagePath,
                durationMs: durationMs,
                waveform: waveform
            )
            let transcript = ChatAIService.mockTranscribeVoice(durationMs: durationMs)
            if let vt = try? await service.fetchVoiceTranscript(messageId: msg.id) {
                try? await service.updateTranscript(id: vt.id, transcript: transcript, status: ChatTranscriptStatus.ready)
                voiceTranscripts[msg.id] = transcript
            }
            messages.append(msg)
            await loadChannelExtras()
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Search

    func runGlobalSearch() async {
        let q = globalSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            searchResults = []
            searchError = nil
            isSearchLoading = false
            return
        }

        isSearchLoading = true
        searchError = nil
        defer { isSearchLoading = false }

        var hits: [ChatSearchHit] = []
        let scopeChannelId = searchScope == .channel ? selectedChannel?.id : nil

        if let service, let workspace, !isOffline {
            do {
                let remote = try await service.searchWorkspace(workspaceId: workspace.id, query: q)
                for m in remote.messages {
                    if let scopeChannelId, m.channel_id != scopeChannelId { continue }
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
                    if scopeChannelId != nil { continue }
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
            } catch {
                searchError = "Cloud search unavailable — showing local results."
            }
        }

        let local = service?.localStore().searchMessages(query: q) ?? []
        for row in local {
            if let scopeChannelId, row.channelId != scopeChannelId { continue }
            let messageId = row.messageId
            if hits.contains(where: { $0.messageId?.uuidString == messageId }) { continue }
            hits.append(ChatSearchHit(
                id: "local-\(messageId)",
                kind: .message,
                title: row.snippet,
                subtitle: row.channelName,
                channelId: row.channelId,
                messageId: UUID(uuidString: messageId),
                createdAt: nil
            ))
        }

        let channelPool = channels + directMessages
        for ch in channelPool {
            if scopeChannelId != nil, ch.id != scopeChannelId { continue }
            let hay = "\(ch.name) \(ch.description ?? "") \(ch.sidebarTitle)".lowercased()
            if hay.contains(q.lowercased()) {
                hits.append(ChatSearchHit(
                    id: "ch-\(ch.id.uuidString)",
                    kind: .channel,
                    title: ch.sidebarTitle,
                    subtitle: ch.kind == .channel ? "Channel" : "Direct message",
                    channelId: ch.id,
                    messageId: nil,
                    createdAt: ch.lastMessageAt
                ))
            }
        }

        if scopeChannelId == nil {
            for profile in profiles.values {
                let display = profile.displayName ?? profile.email ?? "User"
                let name = "\(display) \(profile.email ?? "")".lowercased()
                if name.contains(q.lowercased()) {
                    hits.append(ChatSearchHit(
                        id: "user-\(profile.id.uuidString)",
                        kind: .user,
                        title: display,
                        subtitle: profile.email ?? "Team member",
                        channelId: nil,
                        messageId: nil,
                        createdAt: nil
                    ))
                }
            }
        }

        searchResults = applySearchTabFilter(hits)
    }

    private func applySearchTabFilter(_ hits: [ChatSearchHit]) -> [ChatSearchHit] {
        switch searchTab {
        case .all:
            return hits
        case .messages:
            return hits.filter { $0.kind == .message || $0.kind == .file || $0.kind == .voice }
        case .channels:
            return hits.filter { $0.kind == .channel }
        case .people:
            return hits.filter { $0.kind == .user }
        case .tasks:
            return hits.filter { $0.kind == .task }
        }
    }

    func activateSearchHit(_ hit: ChatSearchHit) {
        switch hit.kind {
        case .user:
            if let profileId = UUID(uuidString: hit.id.replacingOccurrences(of: "user-", with: "")),
               let profile = profiles[profileId] {
                Task { await openDM(with: profile) }
            }
        case .channel, .message, .file, .voice, .task:
            if let channelId = hit.channelId,
               let ch = (channels + directMessages).first(where: { $0.id == channelId }) {
                selectChannel(ch)
            }
        }
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
        guard var ws = workspace, let client = attachedClient else { return }
        let enterprise = EnterpriseWorkspaceService()
        do {
            try await enterprise.persistChatPermissions(
                client: client,
                workspace: &ws,
                permissions: permissions
            )
            workspace = ws
            ChatUserPreferences.cachePermissions(permissions, workspaceId: ws.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
