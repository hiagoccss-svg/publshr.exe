import AppKit
import Foundation

extension ChatViewModel {
    // MARK: - Sidebar hub

    func setSidebarHub(_ hub: ChatSidebarHub) {
        sidebarHub = hub
        if hub == .drafts {
            reloadDraftSummaries()
        } else if hub == .sent {
            Task { await reloadSentSummaries() }
        } else if hub == .activity {
            markAllInAppNotificationsRead()
        }
    }

    func reloadDraftSummaries() {
        guard let store = service?.localStore() else {
            draftSummaries = []
            return
        }
        let drafts = store.loadAllDrafts()
        draftSummaries = drafts.compactMap { draft -> ChatDraftSummary? in
            guard !draft.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            let channel = (channels + directMessages).first { $0.id == draft.channelId }
            let title = channel?.sidebarTitle ?? "Unknown"
            return ChatDraftSummary(
                channelId: draft.channelId,
                channelTitle: title,
                body: draft.body,
                updatedAt: draft.updatedAt
            )
        }
    }

    func reloadSentSummaries() async {
        guard let service, let workspace, let userId = currentUserId else {
            sentSummaries = []
            return
        }
        do {
            let rows = try await service.fetchRecentSentMessages(
                workspaceId: workspace.id,
                userId: userId
            )
            sentSummaries = rows.map { msg in
                let title = (channels + directMessages).first { $0.id == msg.channelId }?.sidebarTitle ?? "Chat"
                return ChatSentMessageSummary(message: msg, channelTitle: title)
            }
        } catch {
            sentSummaries = localSentFromCache(userId: userId)
        }
    }

    private func localSentFromCache(userId: UUID) -> [ChatSentMessageSummary] {
        var items: [ChatSentMessageSummary] = []
        for channel in channels + directMessages {
            guard let msgs = service?.localStore().loadMessages(channelId: channel.id) else { continue }
            for msg in msgs where msg.userId == userId && msg.threadParentId == nil && !msg.isDeleted {
                items.append(ChatSentMessageSummary(message: msg, channelTitle: channel.sidebarTitle))
            }
        }
        return items.sorted { $0.message.createdAt > $1.message.createdAt }.prefix(40).map { $0 }
    }

    func reloadScheduledMessages() async {
        guard let service, let workspace, let userId = currentUserId else {
            scheduledMessages = []
            return
        }
        var merged = service.localStore().loadPendingLocalScheduled(
            workspaceId: workspace.id,
            userId: userId
        )
        if !isOffline {
            if let remote = try? await service.fetchPendingScheduled(
                workspaceId: workspace.id,
                userId: userId
            ) {
                for item in remote where !merged.contains(where: { $0.id == item.id }) {
                    merged.append(item)
                }
            }
        }
        scheduledMessages = merged.sorted { $0.sendAt < $1.sendAt }
        startScheduledMessageDispatcher()
    }

    func startScheduledMessageDispatcher() {
        scheduledDispatchTask?.cancel()
        scheduledDispatchTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                await self?.dispatchDueScheduledMessages()
            }
        }
    }

    func dispatchDueScheduledMessages() async {
        guard let service, let workspace, let userId = currentUserId else { return }
        let now = Date()
        for item in scheduledMessages where item.isPending && item.sendAt <= now {
            do {
                _ = try await service.sendMessageExtended(
                    workspaceId: workspace.id,
                    channelId: item.channelId,
                    userId: userId,
                    body: item.body,
                    threadParentId: item.threadParentId
                )
                service.localStore().updateLocalScheduledStatus(id: item.id, status: "sent")
                try? await service.markScheduledSent(id: item.id, workspaceId: workspace.id)
            } catch {
                continue
            }
        }
        await reloadScheduledMessages()
    }

    // MARK: - Mentions filter

    var unreadMentionChannelIds: Set<UUID> {
        Set(
            inAppNotifications
                .filter { !$0.isRead && $0.category == .mention }
                .map(\.channelId)
        )
    }

    func hasUnreadMention(in channelId: UUID) -> Bool {
        unreadMentionChannelIds.contains(channelId)
            || (unreadCount(for: channelId) > 0 && channelHasCachedMention(channelId))
    }

    func channelHasCachedMention(_ channelId: UUID) -> Bool {
        guard let userId = currentUserId else { return false }
        let msgs = service?.localStore().loadMessages(channelId: channelId) ?? messages
        return msgs.contains { msg in
            msg.userId != userId && messageMentionsCurrentUser(msg)
        }
    }

    // MARK: - Mark unread / copy link

    func markChannelUnread(_ channel: ChatChannel) {
        let next = max(unreadCount(for: channel.id), 1)
        unreadByChannel[channel.id] = next
        service?.localStore().setUnreadCount(channelId: channel.id, count: next)
        refreshDockBadge()
        Task { await markChannelUnreadOnServer(channel) }
    }

    private func markChannelUnreadOnServer(_ channel: ChatChannel) async {
        guard let service, let workspace, let userId = currentUserId else { return }
        let members: [ChatChannelMember]
        if selectedChannel?.id == channel.id, !selectedChannelMembers.isEmpty {
            members = selectedChannelMembers
        } else if let fetched = try? await service.fetchChannelMembers(
            channelId: channel.id,
            workspaceId: workspace.id
        ) {
            members = fetched
        } else {
            return
        }
        guard let member = members.first(where: { $0.userId == userId }) else { return }
        let ancient = Date(timeIntervalSince1970: 0)
        try? await service.updateMemberLastRead(
            memberId: member.id,
            workspaceId: workspace.id,
            lastReadAt: ancient
        )
    }

    func copyChannelLink(_ channel: ChatChannel) {
        let slug = channel.kind == .channel ? channel.name : channel.id.uuidString
        let link = "publshr://chat/\(channel.workspaceId.uuidString)/\(slug)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link, forType: .string)
    }

    func deepLinkURL(for channel: ChatChannel) -> URL? {
        let slug = channel.kind == .channel ? channel.name : channel.id.uuidString
        return URL(string: "publshr://chat/\(channel.workspaceId.uuidString)/\(slug)")
    }

    // MARK: - Composer: mentions & schedule

    func openMentionPicker() {
        mentionPickerQuery = ""
        showMentionPicker = true
    }

    func appendComposerToken(_ token: String) {
        if composerText.isEmpty {
            composerText = token
        } else if composerText.hasSuffix(" ") {
            composerText += token
        } else {
            composerText += " \(token)"
        }
        scheduleDraftSave()
    }

    func insertMention(for profile: Profile) {
        let handle = mentionHandle(for: profile)
        if composerText.isEmpty {
            composerText = "@\(handle) "
        } else if composerText.hasSuffix(" ") {
            composerText += "@\(handle) "
        } else {
            composerText += " @\(handle) "
        }
        showMentionPicker = false
        scheduleDraftSave()
    }

    func mentionHandle(for profile: Profile) -> String {
        let base = profile.displayName ?? profile.email.split(separator: "@").first.map(String.init) ?? "user"
        return base
            .lowercased()
            .replacingOccurrences(of: " ", with: ".")
            .filter { $0.isLetter || $0.isNumber || $0 == "." }
    }

    var mentionPickerCandidates: [Profile] {
        let q = mentionPickerQuery.trimmingCharacters(in: .whitespaces).lowercased()
        var list = Array(profiles.values)
        if let me = currentUserId {
            list = list.filter { $0.id != me }
        }
        list.sort { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }
        guard !q.isEmpty else { return list }
        return list.filter {
            ($0.displayName?.lowercased().contains(q) ?? false)
                || $0.email.lowercased().contains(q)
                || mentionHandle(for: $0).contains(q)
        }
    }

    func scheduleCurrentMessage() async {
        guard let service, let workspace, let channel = selectedChannel, let userId = currentUserId else { return }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard scheduleSendAt > Date().addingTimeInterval(30) else {
            errorMessage = "Pick a time at least 30 seconds from now."
            return
        }
        let localId = UUID()
        var item = ChatScheduledMessage(
            id: localId,
            workspaceId: workspace.id,
            channelId: channel.id,
            userId: userId,
            body: text,
            threadParentId: replyingTo?.id,
            sendAt: scheduleSendAt,
            status: "pending",
            createdAt: Date(),
            updatedAt: Date()
        )
        service.localStore().saveLocalScheduled(item)
        composerText = ""
        service.localStore().saveDraft(ChatDraft(channelId: channel.id, body: "", updatedAt: Date()))
        showScheduleSendSheet = false
        if !isOffline {
            do {
                let remote = try await service.createScheduledMessage(
                    workspaceId: workspace.id,
                    channelId: channel.id,
                    userId: userId,
                    body: text,
                    sendAt: scheduleSendAt,
                    threadParentId: replyingTo?.id
                )
                service.localStore().deleteLocalScheduled(id: localId)
                item = remote
                service.localStore().saveLocalScheduled(item)
            } catch {
                errorMessage = "Scheduled locally — will send when online: \(error.localizedDescription)"
            }
        }
        replyingTo = nil
        await reloadScheduledMessages()
    }

    func cancelScheduled(_ item: ChatScheduledMessage) async {
        service?.localStore().updateLocalScheduledStatus(id: item.id, status: "cancelled")
        if let service, let workspace = workspace {
            try? await service.cancelScheduledMessage(id: item.id, workspaceId: workspace.id)
        }
        await reloadScheduledMessages()
    }

    // MARK: - Assign message

    func assignMessage(_ message: ChatMessage, to profile: Profile?) async {
        guard let service, let workspace else { return }
        do {
            let updated = try await service.assignMessage(
                workspaceId: workspace.id,
                messageId: message.id,
                assignedTo: profile?.id
            )
            if selectedChannel?.id == message.channelId,
               let idx = messages.firstIndex(where: { $0.id == message.id }) {
                messages[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func assignedDisplayName(for message: ChatMessage) -> String? {
        guard let uid = message.assignedTo else { return nil }
        return displayName(for: uid)
    }

    var showInspectorForSelectedChannel: Bool {
        guard let channel = selectedChannel else { return false }
        return showDMInspector && (channel.kind == .dm || channel.kind == .group)
    }
}
