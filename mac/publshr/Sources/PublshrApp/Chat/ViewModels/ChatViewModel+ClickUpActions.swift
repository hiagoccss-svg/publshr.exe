import AppKit
import Foundation

// MARK: - ClickUp-style channel & message actions (Phase A + task-from-message)

extension ChatViewModel {
    func reloadClickUpLocalState() {
        guard let workspace, let service else { return }
        _ = ChatUserPreferences.loadClosedDMIds(workspaceId: workspace.id)
        _ = ChatUserPreferences.loadUnfollowedChannelIds(workspaceId: workspace.id)
        let all = service.cachedChannels(workspaceId: workspace.id)
        if !all.isEmpty { partitionChannels(all) }
    }

    /// Hide closed DMs from sidebar until a new message arrives.
    func applyClosedDMFilter() {
        guard let workspace else { return }
        let closed = ChatUserPreferences.loadClosedDMIds(workspaceId: workspace.id)
        directMessages = directMessages.filter { ch in
            guard ch.kind == .dm || ch.kind == .group else { return true }
            return !closed.contains(ch.id)
        }
    }

    func isFollowing(_ channel: ChatChannel) -> Bool {
        isFollowing(channelId: channel.id)
    }

    func toggleFollow(_ channel: ChatChannel) {
        guard let workspace else { return }
        var ids = ChatUserPreferences.loadUnfollowedChannelIds(workspaceId: workspace.id)
        if ids.contains(channel.id) {
            ids.remove(channel.id)
        } else {
            ids.insert(channel.id)
        }
        ChatUserPreferences.saveUnfollowedChannelIds(ids, workspaceId: workspace.id)
    }

    func closeDirectMessage(_ channel: ChatChannel) {
        guard channel.kind == .dm || channel.kind == .group, let workspace else { return }
        var closed = ChatUserPreferences.loadClosedDMIds(workspaceId: workspace.id)
        closed.insert(channel.id)
        ChatUserPreferences.saveClosedDMIds(closed, workspaceId: workspace.id)
        if selectedChannel?.id == channel.id {
            selectedChannel = nil
            messages = []
        }
        applyClosedDMFilter()
    }

    func reopenClosedDMIfNeeded(channelId: UUID) {
        guard let workspace else { return }
        var closed = ChatUserPreferences.loadClosedDMIds(workspaceId: workspace.id)
        guard closed.contains(channelId) else { return }
        closed.remove(channelId)
        ChatUserPreferences.saveClosedDMIds(closed, workspaceId: workspace.id)
        Task {
            guard let service, let userId = currentUserId else { return }
            let all = (try? await service.fetchChannels(workspaceId: workspace.id)) ?? []
            let dm = all.filter { ($0.kind == .dm || $0.kind == .group) && $0.id == channelId }
            if let ch = dm.first {
                if !directMessages.contains(where: { $0.id == ch.id }) {
                    directMessages.append(ch)
                    directMessages.sort {
                        $0.sidebarTitle.localizedCaseInsensitiveCompare($1.sidebarTitle) == .orderedAscending
                    }
                }
            }
        }
    }

    func markChannelUnread(_ channel: ChatChannel) {
        let count = max(unreadCount(for: channel.id), 1)
        unreadByChannel[channel.id] = count
        service?.localStore().setUnreadCount(channelId: channel.id, count: count)
        refreshDockBadge()
        Task {
            guard let service, let member = membershipByChannel[channel.id] else { return }
            let anchor = channel.lastMessageAt ?? Date.distantPast
            let back = anchor.addingTimeInterval(-1)
            if let updated = try? await service.updateMemberLastReadAt(memberId: member.id, at: back) {
                membershipByChannel[channel.id] = updated
            }
        }
    }

    func persistChannelRead(_ channel: ChatChannel) {
        Task {
            guard let service, let member = membershipByChannel[channel.id] else { return }
            if let updated = try? await service.updateMemberLastReadAt(memberId: member.id, at: Date()) {
                membershipByChannel[channel.id] = updated
            }
        }
    }

    func copyChannelLink(_ channel: ChatChannel) {
        guard let workspace else { return }
        let url = "publshr://workspace/\(workspace.id.uuidString)/chat/\(channel.id.uuidString)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        flashCopiedFeedback("Channel link copied")
    }

    func copyMessageLink(_ message: ChatMessage) {
        guard let workspace else { return }
        let url = "publshr://workspace/\(workspace.id.uuidString)/chat/\(message.channelId.uuidString)#message/\(message.id.uuidString)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        flashCopiedFeedback("Message link copied")
    }

    func copyMessageText(_ message: ChatMessage) {
        let text = message.body ?? ""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        flashCopiedFeedback("Message copied")
    }

    private func flashCopiedFeedback(_ text: String) {
        lastCopiedFeedback = text
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if lastCopiedFeedback == text { lastCopiedFeedback = nil }
        }
    }

    func beginRenameChannel(_ channel: ChatChannel) {
        guard channel.kind == .channel else { return }
        renameChannelTarget = channel
    }

    func commitRenameChannel(id: UUID, newName: String) async {
        guard let service, let workspace else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var slug = trimmed.lowercased()
        if slug.hasPrefix("#") { slug.removeFirst() }
        slug = slug.replacingOccurrences(of: " ", with: "-")
        do {
            let updated = try await service.updateChannel(
                channelId: id,
                workspaceId: workspace.id,
                name: slug,
                description: channels.first(where: { $0.id == id })?.description
            )
            replaceChannelInLists(updated)
            if selectedChannel?.id == id { selectedChannel = updated }
            renameChannelTarget = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func replaceChannelInLists(_ channel: ChatChannel) {
        if let i = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[i] = channel
        }
        if let i = directMessages.firstIndex(where: { $0.id == channel.id }) {
            directMessages[i] = channel
        }
    }

    func createTaskFromMessage(_ message: ChatMessage, title: String?) async {
        guard let service, let workspace, let userId = currentUserId else { return }
        let raw = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskTitle: String = {
            if let raw, !raw.isEmpty { return String(raw.prefix(200)) }
            let body = (message.body ?? "Task from chat").trimmingCharacters(in: .whitespacesAndNewlines)
            return String(body.prefix(200))
        }()
        let desc = "Created from chat message \(message.id.uuidString)"
        do {
            let task = try await service.createPlannerItem(
                workspaceId: workspace.id,
                title: taskTitle,
                createdBy: userId,
                description: desc
            )
            let preview = ChatLinkPreview(
                title: task.title,
                status: task.status,
                dueDate: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
                owner: task.assigneeId.flatMap { displayName(for: $0) },
                subtitle: "From chat"
            )
            _ = try await service.attachLink(
                workspaceId: workspace.id,
                messageId: message.id,
                linkType: .task,
                linkId: task.id,
                preview: preview
            )
            await loadChannelExtras()
            await loadPlannerTasks()
            flashCopiedFeedback("Task created")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func linkMessageToPlannerTask(_ message: ChatMessage, task: PlannerTask) async {
        guard let service, let workspace else { return }
        let preview = ChatLinkPreview(
            title: task.title,
            status: task.status,
            dueDate: task.dueDate.map { ISO8601DateFormatter().string(from: $0) },
            owner: task.assigneeId.flatMap { displayName(for: $0) }
        )
        do {
            let link = try await service.attachLink(
                workspaceId: workspace.id,
                messageId: message.id,
                linkType: .task,
                linkId: task.id,
                preview: preview
            )
            var existing = links[message.id] ?? []
            if !existing.contains(where: { $0.linkId == task.id }) {
                existing.append(link)
                links[message.id] = existing
            }
            linkTaskForMessage = nil
            flashCopiedFeedback("Linked to task")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func shouldNotifyForChannel(_ channelId: UUID) -> Bool {
        guard isFollowing(channelId: channelId) else { return false }
        if let ch = (channels + directMessages).first(where: { $0.id == channelId }) {
            return !isChannelMuted(ch)
        }
        return true
    }

    private func isFollowing(channelId: UUID) -> Bool {
        guard let workspace else { return true }
        return !ChatUserPreferences.loadUnfollowedChannelIds(workspaceId: workspace.id).contains(channelId)
    }
}
