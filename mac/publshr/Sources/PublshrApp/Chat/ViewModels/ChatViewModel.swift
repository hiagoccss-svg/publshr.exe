import Foundation
import Supabase

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var workspace: Workspace?
    @Published var channels: [ChatChannel] = []
    @Published var directMessages: [ChatChannel] = []
    @Published var selectedChannel: ChatChannel?
    @Published var messages: [ChatMessage] = []
    @Published var profiles: [UUID: Profile] = [:]
    @Published var presence: [UUID: ChatPresence] = [:]
    @Published var composerText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""
    @Published var myStatus: ChatPresenceStatus = .online
    @Published var typingUsers: [ChatTypingState] = []
    @Published var unreadByChannel: [UUID: Int] = [:]
    @Published var permissions = ChatWorkspacePermissions.default
    @Published var isOffline = false

    // Phase 2
    @Published var reactions: [UUID: [ChatReactionSummary]] = [:]
    @Published var links: [UUID: [ChatMessageLink]] = [:]
    @Published var pinnedItems: [ChatPinnedItem] = []
    @Published var threadCounts: [UUID: Int] = [:]
    @Published var activeThreadParent: ChatMessage?
    @Published var threadMessages: [ChatMessage] = []
    @Published var threadComposerText = ""
    @Published var showThreadPanel = false
    @Published var showPinnedPanel = false
    @Published var uploadProgress: Double?
    @Published var editingMessageId: UUID?

    // Phase 3
    @Published var plannerTasks: [PlannerTask] = []
    @Published var showPermissionsSheet = false
    @Published var voiceTranscripts: [UUID: String] = [:]

    // Phase 4
    @Published var showSearchSheet = false
    @Published var showAISheet = false
    @Published var globalSearchQuery = ""
    @Published var searchResults: [ChatSearchHit] = []
    @Published var aiResult: ChatAIResult?
    @Published var isAILoading = false

    private var auth: AuthViewModel?
    var service: ChatService?
    private var draftSaveTask: Task<Void, Never>?
    private var presenceHeartbeat: Task<Void, Never>?
    private var didAttach = false

    var currentUserId: UUID? { auth?.profile?.id }

    func attach(auth: AuthViewModel) {
        guard !didAttach else { return }
        didAttach = true
        self.auth = auth
        service = ChatService(client: auth.client)
    }

    /// Called when user picks a workspace — loads channels/chat for that workspace only.
    func applyWorkspaceContext(workspace: Workspace?, permissions: ChatWorkspacePermissions, auth: AuthViewModel) {
        self.auth = auth
        if service == nil {
            service = ChatService(client: auth.client)
        }
        self.permissions = permissions
        guard let workspace, let userId = auth.profile?.id ?? auth.session?.user.id else {
            detach()
            return
        }
        guard self.workspace?.id != workspace.id else { return }
        Task {
            presenceHeartbeat?.cancel()
            await service?.stopRealtime()
            self.workspace = workspace
            parsePermissions(from: workspace)
            self.permissions = permissions
            messages = []
            channels = []
            directMessages = []
            selectedChannel = nil
            await loadWorkspaceData(workspaceId: workspace.id, userId: userId)
            startRealtime(workspaceId: workspace.id)
            startPresenceHeartbeat(workspaceId: workspace.id, userId: userId)
        }
    }

    func detach() {
        presenceHeartbeat?.cancel()
        draftSaveTask?.cancel()
        Task { await service?.stopRealtime() }
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let auth, auth.isAuthenticated, let userId = auth.profile?.id else { return }
        isLoading = true
        defer { isLoading = false }

        await ChatNotificationService.shared.requestAuthorization()

        do {
            var workspaces = try await service?.fetchMemberWorkspaces(userId: userId) ?? []
            if workspaces.isEmpty {
                workspaces = try await service?.fetchWorkspaces() ?? []
            }
            if workspaces.isEmpty {
                let created = try await service?.createWorkspace(name: "\(auth.profile?.displayName ?? "My") Workspace")
                if let created { workspaces = [created] }
            }
            guard let ws = workspaces.first else {
                errorMessage = "Create a workspace to start chatting."
                loadOfflineCache(userId: userId)
                return
            }
            workspace = ws
            parsePermissions(from: ws)
            await loadWorkspaceData(workspaceId: ws.id, userId: userId)
            startRealtime(workspaceId: ws.id)
            startPresenceHeartbeat(workspaceId: ws.id, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            isOffline = true
            loadOfflineCache(userId: userId)
        }
    }

    private func loadOfflineCache(userId: UUID) {
        guard let service else { return }
        if let wsId = UUID(uuidString: service.localStore().meta("last_workspace_id") ?? "") {
            channels = service.cachedChannels(workspaceId: wsId).filter { $0.kind == .channel }
            directMessages = service.cachedChannels(workspaceId: wsId).filter { $0.kind == .dm || $0.kind == .group }
            presence = Dictionary(uniqueKeysWithValues: service.localStore().loadPresence(workspaceId: wsId).map { ($0.userId, $0) })
        }
        _ = userId
    }

    private func parsePermissions(from ws: Workspace) {
        guard let chat = ws.settings?["chat"], case .object(let obj) = chat else { return }
        func bool(_ key: String, _ path: WritableKeyPath<ChatWorkspacePermissions, Bool>) {
            if case .bool(let v) = obj[key] { permissions[keyPath: path] = v }
        }
        bool("can_create_channels", \.canCreateChannels)
        bool("can_create_group_chats", \.canCreateGroupChats)
        bool("can_dm", \.canDM)
        bool("can_invite_users", \.canInviteUsers)
        bool("can_add_guests", \.canAddGuests)
        bool("can_delete_messages", \.canDeleteMessages)
        bool("can_edit_messages", \.canEditMessages)
        bool("can_pin_messages", \.canPinMessages)
        bool("can_upload_files", \.canUploadFiles)
        bool("can_use_voice_notes", \.canUseVoiceNotes)
        bool("can_export_chats", \.canExportChats)
        bool("read_receipts_enabled", \.readReceiptsEnabled)
    }

    private func loadWorkspaceData(workspaceId: UUID, userId: UUID) async {
        guard let service else { return }
        service.localStore().setMeta("last_workspace_id", value: workspaceId.uuidString)

        let cached = service.cachedChannels(workspaceId: workspaceId)
        if !cached.isEmpty {
            partitionChannels(cached)
        }

        async let remoteChannels = service.fetchChannels(workspaceId: workspaceId)
        async let remoteProfiles = service.fetchWorkspaceProfiles(workspaceId: workspaceId)
        async let remotePresence = service.fetchPresence(workspaceId: workspaceId)

        do {
            try await service.seedDefaultChannels(workspaceId: workspaceId, userId: userId)
            let all = try await remoteChannels
            partitionChannels(all)
            let profs = try await remoteProfiles
            profiles = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })
            let pres = try await remotePresence
            presence = Dictionary(uniqueKeysWithValues: pres.map { ($0.userId, $0) })
            isOffline = false
            errorMessage = nil
        } catch {
            if channels.isEmpty { errorMessage = error.localizedDescription }
            isOffline = true
        }
    }

    private func partitionChannels(_ all: [ChatChannel]) {
        channels = all.filter { $0.kind == .channel }.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
        directMessages = all.filter { $0.kind == .dm || $0.kind == .group }.sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
    }

    // MARK: - Channel selection

    func selectChannel(_ channel: ChatChannel) {
        selectedChannel = channel
        unreadByChannel[channel.id] = 0
        service?.localStore().setUnreadCount(channelId: channel.id, count: 0)
        if let draft = service?.localStore().loadDraft(channelId: channel.id) {
            composerText = draft.body
        } else {
            composerText = ""
        }
        Task { await loadMessages(for: channel) }
    }

    func loadMessages(for channel: ChatChannel) async {
        guard let service, let workspace else { return }
        let cached = service.cachedMessages(channelId: channel.id)
        if !cached.isEmpty { messages = cached }
        do {
            messages = try await service.fetchMainChannelMessages(channelId: channel.id, workspaceId: workspace.id)
            await loadChannelExtras()
            await markMessagesSeen()
        } catch {
            if messages.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Send

    func sendMessage() async {
        guard let service, let workspace, let channel = selectedChannel,
              let userId = currentUserId else { return }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let optimisticId = UUID()
        var optimistic = ChatMessage(
            id: optimisticId,
            workspaceId: workspace.id,
            channelId: channel.id,
            userId: userId,
            body: text,
            threadParentId: nil,
            attachments: [],
            isEdited: false,
            isDeleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        optimistic.localStatus = .sending
        messages.append(optimistic)
        composerText = ""
        service.localStore().saveDraft(ChatDraft(channelId: channel.id, body: "", updatedAt: Date()))

        do {
            let sent = try await service.sendMessageExtended(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: userId,
                body: text
            )
            if let idx = messages.firstIndex(where: { $0.id == optimisticId }) {
                var confirmed = sent
                confirmed.localStatus = .sent
                messages[idx] = confirmed
            }
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == optimisticId }) {
                var failed = messages[idx]
                failed.localStatus = .failed
                messages[idx] = failed
            }
            composerText = text
        }
    }

    func retryMessage(_ message: ChatMessage) async {
        guard message.localStatus == .failed, let body = message.body else { return }
        composerText = body
        if let idx = messages.firstIndex(where: { $0.id == message.id }) {
            messages.remove(at: idx)
        }
        await sendMessage()
    }

    func scheduleDraftSave() {
        draftSaveTask?.cancel()
        guard let channelId = selectedChannel?.id else { return }
        draftSaveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            service?.localStore().saveDraft(ChatDraft(
                channelId: channelId,
                body: composerText,
                updatedAt: Date()
            ))
        }
    }

    // MARK: - Channels / DMs

    func createChannel(name: String) async {
        guard permissions.canCreateChannels,
              let service, let workspace, let userId = currentUserId else { return }
        let clean = name.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard !clean.isEmpty else { return }
        do {
            let ch = try await service.createChannel(
                workspaceId: workspace.id,
                name: clean,
                createdBy: userId
            )
            channels.insert(ch, at: 0)
            selectChannel(ch)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openDM(with profile: Profile) async {
        guard permissions.canDM,
              let service, let workspace, let userId = currentUserId else { return }
        do {
            let dm = try await service.createDM(
                workspaceId: workspace.id,
                currentUserId: userId,
                otherUserId: profile.id,
                otherDisplayName: profile.displayName ?? profile.email
            )
            if !directMessages.contains(where: { $0.id == dm.id }) {
                directMessages.insert(dm, at: 0)
            }
            selectChannel(dm)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Presence

    func setStatus(_ status: ChatPresenceStatus) async {
        myStatus = status
        guard let service, let workspace, let userId = currentUserId else { return }
        try? await service.upsertPresence(workspaceId: workspace.id, userId: userId, status: status)
        presence[userId] = ChatPresence(
            workspaceId: workspace.id,
            userId: userId,
            status: status,
            activity: nil,
            lastSeenAt: Date(),
            updatedAt: Date()
        )
    }

    func presence(for userId: UUID) -> ChatPresenceStatus {
        presence[userId]?.status ?? .offline
    }

    func displayName(for userId: UUID) -> String {
        if userId == currentUserId { return "You" }
        return profiles[userId]?.displayName ?? profiles[userId]?.email ?? "Member"
    }

    private func startPresenceHeartbeat(workspaceId: UUID, userId: UUID) {
        presenceHeartbeat?.cancel()
        presenceHeartbeat = Task {
            while !Task.isCancelled {
                try? await service?.upsertPresence(workspaceId: workspaceId, userId: userId, status: myStatus)
                try? await Task.sleep(nanoseconds: 45_000_000_000)
            }
        }
    }

    // MARK: - Realtime

    private func startRealtime(workspaceId: UUID) {
        let handler = IncomingMessageHandler(viewModel: self)
        service?.subscribeMessages(workspaceId: workspaceId, onInsert: handler.handleMessage)
        service?.subscribePresence(workspaceId: workspaceId, onChange: handler.handlePresence)
        service?.subscribeReactions(workspaceId: workspaceId, onChange: handler.handleReactions)
    }

    func handleIncomingMessage(_ message: ChatMessage) {
        if selectedChannel?.id == message.channelId {
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
            if let parent = message.threadParentId {
                threadCounts[parent, default: 0] += 1
                if activeThreadParent?.id == parent, !threadMessages.contains(where: { $0.id == message.id }) {
                    threadMessages.append(message)
                }
            }
            Task { await loadChannelExtras() }
        } else {
            let count = (unreadByChannel[message.channelId] ?? 0) + 1
            unreadByChannel[message.channelId] = count
            service?.localStore().setUnreadCount(channelId: message.channelId, count: count)
            if message.userId != currentUserId {
                let channelName = (channels + directMessages).first { $0.id == message.channelId }?.displayTitle ?? "Chat"
                let author = displayName(for: message.userId)
                ChatNotificationService.shared.notify(
                    title: channelName,
                    body: "\(author): \(message.body ?? "")",
                    channelId: message.channelId,
                    messageId: message.id
                )
            }
        }
        updateChannelPreview(message)
    }

    private func updateChannelPreview(_ message: ChatMessage) {
        func bump(_ list: inout [ChatChannel], index: Int) {
            var ch = list[index]
            ch.lastMessageAt = message.createdAt
            ch.messageCount += 1
            list[index] = ch
        }
        if let i = channels.firstIndex(where: { $0.id == message.channelId }) { bump(&channels, index: i) }
        if let i = directMessages.firstIndex(where: { $0.id == message.channelId }) { bump(&directMessages, index: i) }
    }

    // MARK: - Search filter

    var filteredChannels: [ChatChannel] {
        filter(channels)
    }

    var filteredDMs: [ChatChannel] {
        filter(directMessages)
    }

    private func filter(_ list: [ChatChannel]) -> [ChatChannel] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter { $0.name.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false) }
    }

    var totalUnread: Int {
        unreadByChannel.values.reduce(0, +)
    }
}

/// Bridges realtime callbacks into the main-actor view model without Swift 6 capture errors.
private final class IncomingMessageHandler: @unchecked Sendable {
    private weak var viewModel: ChatViewModel?

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    func handleMessage(_ message: ChatMessage) {
        Task { @MainActor [weak viewModel] in
            viewModel?.handleIncomingMessage(message)
        }
    }

    func handlePresence(_ record: ChatPresence) {
        Task { @MainActor [weak viewModel] in
            viewModel?.presence[record.userId] = record
        }
    }

    func handleReactions() {
        Task { @MainActor [weak viewModel] in
            await viewModel?.loadChannelExtras()
        }
    }
}
