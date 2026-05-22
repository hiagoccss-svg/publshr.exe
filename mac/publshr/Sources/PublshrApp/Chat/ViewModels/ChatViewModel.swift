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
    @Published var myStatus: ChatPresenceStatus = ChatUserPreferences.loadMyStatus()
    @Published var replyingTo: ChatMessage?
    @Published var typingUsers: [ChatTypingState] = []
    @Published var unreadByChannel: [UUID: Int] = [:]
    @Published var unreadThreadsByChannel: [UUID: Int] = [:]
    @Published var sidebarFilter: ChatSidebarFilter = ChatUserPreferences.loadSidebarFilter()
    @Published var sidebarLayout: ChatSidebarLayout = ChatUserPreferences.loadSidebarLayout()
    @Published var sidebarSearchQuery = ""
    @Published private(set) var pinnedSidebarChannelIds: Set<UUID> = []
    @Published var permissions = ChatWorkspacePermissions.default
    @Published var isOffline = false
    @Published private(set) var inAppNotifications: [ChatInAppNotification] = []

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
    @Published var chatFocusMode = false
    @Published var uploadProgress: Double?
    @Published var editingMessageId: UUID?

    // Phase 3
    @Published var plannerTasks: [PlannerTask] = []
    @Published var showPermissionsSheet = false
    @Published var showChannelSettings = false
    @Published var selectedChannelMembers: [ChatChannelMember] = []
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
    private var typingBroadcaster: ChatTypingBroadcaster?
    private var typingListenTask: Task<Void, Never>?
    private var composerTypingTask: Task<Void, Never>?
    private var typingExpiryTask: Task<Void, Never>?
    private var didAttach = false
    private var navigationBackStack: [UUID] = []
    private var navigationForwardStack: [UUID] = []
    private var notificationLevelByChannel: [UUID: String] = [:]
    private var deliveredMacNotificationMessageIds = Set<UUID>()
    private let maxInAppNotifications = 80

    var currentUserId: UUID? { auth?.profile?.id ?? auth?.session?.user.id }
    var attachedClient: SupabaseClient? { auth?.client }

    func attach(auth: AuthViewModel) {
        self.auth = auth
        if service == nil {
            service = ChatService(client: auth.client)
        }
        didAttach = true
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
        let sameWorkspace = self.workspace?.id == workspace.id
        if sameWorkspace, (!channels.isEmpty || !directMessages.isEmpty), errorMessage == nil {
            return
        }
        Task {
            presenceHeartbeat?.cancel()
            await service?.stopRealtime()
            self.workspace = workspace
            reloadPinnedSidebarChannels()
            mergePermissions(workspace: workspace, fallback: permissions)
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
        composerTypingTask?.cancel()
        typingListenTask?.cancel()
        Task {
            await typingBroadcaster?.unsubscribe()
            await service?.stopRealtime()
        }
        typingBroadcaster = nil
        typingExpiryTask?.cancel()
        typingExpiryTask = nil
        typingUsers = []
        inAppNotifications = []
        deliveredMacNotificationMessageIds = []
        notificationLevelByChannel = [:]
        ChatNotificationFocusState.shared.setActiveChannel(nil)
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        guard let auth, auth.isAuthenticated, let userId = auth.profile?.id else { return }
        isLoading = true
        defer { isLoading = false }

        SystemPermissionStore.migrateLegacyPromptFlagsIfNeeded()
        await ChatNotificationService.shared.requestAuthorizationIfNeeded()

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
            mergePermissions(workspace: ws, fallback: auth.workspaceChatPermissions)
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

    func mergePermissions(workspace ws: Workspace, fallback: ChatWorkspacePermissions) {
        if let cached = ChatUserPreferences.cachedPermissions(workspaceId: ws.id) {
            permissions = cached
        } else {
            permissions = fallback
        }
        applyPermissionsFromWorkspace(ws)
        ChatUserPreferences.cachePermissions(permissions, workspaceId: ws.id)
    }

    private func applyPermissionsFromWorkspace(_ ws: Workspace) {
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
        ChatUserPreferences.cachePermissions(permissions, workspaceId: ws.id)
    }

    private func loadWorkspaceData(workspaceId: UUID, userId: UUID) async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }
        service.localStore().setMeta("last_workspace_id", value: workspaceId.uuidString)

        let cached = service.cachedChannels(workspaceId: workspaceId)
        if !cached.isEmpty {
            partitionChannels(cached)
            selectFirstChannelIfNeeded()
        }

        async let remoteChannels = service.fetchChannels(workspaceId: workspaceId)
        async let remoteProfiles = service.fetchWorkspaceProfiles(workspaceId: workspaceId)
        async let remotePresence = service.fetchPresence(workspaceId: workspaceId)
        async let remoteMemberships = service.fetchMyChannelMemberships(
            workspaceId: workspaceId,
            userId: userId
        )

        do {
            try await service.seedDefaultChannels(workspaceId: workspaceId, userId: userId)
            let memberships = try await remoteMemberships
            notificationLevelByChannel = Dictionary(
                uniqueKeysWithValues: memberships.map { ($0.channelId, $0.notificationLevel) }
            )
            let all = try await remoteChannels
            partitionChannels(all)
            var unreadMap: [UUID: Int] = [:]
            for ch in all {
                let c = service.localStore().unreadCount(channelId: ch.id)
                if c > 0 { unreadMap[ch.id] = c }
            }
            unreadByChannel = unreadMap
            let profs = try await remoteProfiles
            profiles = Dictionary(uniqueKeysWithValues: profs.map { ($0.id, $0) })
            let pres = try await remotePresence
            presence = Dictionary(uniqueKeysWithValues: pres.map { ($0.userId, $0) })
            isOffline = false
            errorMessage = nil
            selectFirstChannelIfNeeded()
            await loadPlannerTasks()
            if filteredChannels.isEmpty, filteredDMs.isEmpty,
               sidebarFilter != .all, !channels.isEmpty || !directMessages.isEmpty {
                setSidebarFilter(.all)
            }
        } catch {
            if channels.isEmpty { errorMessage = error.localizedDescription }
            isOffline = true
            if sidebarFilter != .all { setSidebarFilter(.all) }
        }
    }

    func hasChannel(_ channelId: UUID) -> Bool {
        channels.contains { $0.id == channelId } || directMessages.contains { $0.id == channelId }
    }

    func upsertProfile(_ profile: Profile) {
        profiles[profile.id] = profile
    }

    private func selectFirstChannelIfNeeded() {
        guard selectedChannel == nil else { return }
        if let first = channels.first ?? directMessages.first {
            selectChannel(first)
        }
    }

    private func partitionChannels(_ all: [ChatChannel]) {
        channels = all
            .filter { $0.kind == .channel }
            .sorted { $0.sidebarTitle.localizedCaseInsensitiveCompare($1.sidebarTitle) == .orderedAscending }
        directMessages = all
            .filter { $0.kind == .dm || $0.kind == .group }
            .sorted { $0.sidebarTitle.localizedCaseInsensitiveCompare($1.sidebarTitle) == .orderedAscending }
    }

    // MARK: - Channel selection

    func selectChannel(_ channel: ChatChannel, recordHistory: Bool = true) {
        if recordHistory, let previousId = selectedChannel?.id, previousId != channel.id {
            navigationBackStack.append(previousId)
            if navigationBackStack.count > 32 {
                navigationBackStack.removeFirst()
            }
            navigationForwardStack.removeAll()
        }
        selectedChannel = channel
        ChatNotificationFocusState.shared.setActiveChannel(channel.id)
        replyingTo = nil
        markInAppNotificationsRead(for: channel.id)
        unreadByChannel[channel.id] = 0
        unreadThreadsByChannel[channel.id] = 0
        service?.localStore().setUnreadCount(channelId: channel.id, count: 0)
        refreshDockBadge()
        Task { await subscribeTyping(for: channel.id) }
        Task { await loadChannelMembers(for: channel) }
        if let draft = service?.localStore().loadDraft(channelId: channel.id) {
            composerText = draft.body
        } else {
            composerText = ""
        }
        Task { await loadMessages(for: channel) }
    }

    var canNavigateBack: Bool { !navigationBackStack.isEmpty }
    var canNavigateForward: Bool { !navigationForwardStack.isEmpty }

    func navigateBack() {
        guard let currentId = selectedChannel?.id,
              let previousId = navigationBackStack.popLast() else { return }
        navigationForwardStack.append(currentId)
        selectChannelById(previousId, recordHistory: false)
    }

    func navigateForward() {
        guard let currentId = selectedChannel?.id,
              let nextId = navigationForwardStack.popLast() else { return }
        navigationBackStack.append(currentId)
        selectChannelById(nextId, recordHistory: false)
    }

    func profile(for userId: UUID) -> Profile? {
        if userId == currentUserId, let live = auth?.profile {
            return live
        }
        return profiles[userId]
    }

    func channelMemberCount(for channel: ChatChannel) -> Int {
        if channel.id == selectedChannel?.id, !selectedChannelMembers.isEmpty {
            return selectedChannelMembers.count
        }
        switch channel.kind {
        case .dm:
            return 2
        case .group, .channel, .thread:
            return max(selectedChannelMembers.count, 1)
        }
    }

    var canManageSelectedChannel: Bool {
        guard let channel = selectedChannel, let userId = currentUserId else { return false }
        if auth?.selectedMembership?.role.canManageWorkspace == true { return true }
        if channel.createdBy == userId { return true }
        return selectedChannelMembers.contains { $0.userId == userId && ($0.role == "owner" || $0.role == "admin") }
    }

    func canPost(in channel: ChatChannel) -> Bool {
        guard channel.visibility.blocksNonAdminPosts else { return true }
        return canManageChannel(channel)
    }

    func canManageChannel(_ channel: ChatChannel) -> Bool {
        guard let userId = currentUserId else { return false }
        if auth?.selectedMembership?.role.canManageWorkspace == true { return true }
        if channel.createdBy == userId { return true }
        if channel.id == selectedChannel?.id {
            return selectedChannelMembers.contains { $0.userId == userId && ($0.role == "owner" || $0.role == "admin") }
        }
        return false
    }

    func myChannelMemberRecord() -> ChatChannelMember? {
        guard let userId = currentUserId else { return nil }
        return selectedChannelMembers.first { $0.userId == userId }
    }

    func loadChannelMembers(for channel: ChatChannel) async {
        guard let service, let workspace else { return }
        do {
            selectedChannelMembers = try await service.fetchChannelMembers(
                channelId: channel.id,
                workspaceId: workspace.id
            )
            if let userId = currentUserId,
               let mine = selectedChannelMembers.first(where: { $0.userId == userId }) {
                notificationLevelByChannel[channel.id] = mine.notificationLevel
            }
        } catch {
            if channel.kind == .dm { selectedChannelMembers = [] }
        }
    }

    func inviteMemberToSelectedChannel(profile: Profile) async {
        guard permissions.canInviteUsers,
              let service, let workspace, let channel = selectedChannel,
              channel.kind != .dm else { return }
        guard !selectedChannelMembers.contains(where: { $0.userId == profile.id }) else { return }
        do {
            try await service.addChannelMember(
                workspaceId: workspace.id,
                channelId: channel.id,
                userId: profile.id
            )
            await loadChannelMembers(for: channel)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeMemberFromSelectedChannel(_ member: ChatChannelMember) async {
        guard let service, let workspace, let channel = selectedChannel else { return }
        let isSelf = member.userId == currentUserId
        guard isSelf || canManageSelectedChannel else {
            errorMessage = "You do not have permission to remove members."
            return
        }
        do {
            try await service.removeChannelMember(memberId: member.id, workspaceId: workspace.id)
            selectedChannelMembers.removeAll { $0.id == member.id }
            if isSelf {
                selectedChannel = nil
                ChatNotificationFocusState.shared.setActiveChannel(nil)
                channels.removeAll { $0.id == channel.id }
                directMessages.removeAll { $0.id == channel.id }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSelectedChannelSettings(
        name: String?,
        description: String?,
        visibility: ChatChannelVisibility?
    ) async {
        guard canManageSelectedChannel,
              let service, let workspace, var channel = selectedChannel else { return }
        do {
            let updated = try await service.updateChannel(
                channelId: channel.id,
                workspaceId: workspace.id,
                name: name,
                description: description,
                visibility: visibility,
                isArchived: nil
            )
            channel = updated
            replaceChannelInLists(updated)
            selectedChannel = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setSelectedChannelNotificationLevel(_ level: String) async {
        guard let service, let workspace, let record = myChannelMemberRecord() else { return }
        do {
            try await service.updateChannelMemberNotification(
                memberId: record.id,
                workspaceId: workspace.id,
                level: level
            )
            if let idx = selectedChannelMembers.firstIndex(where: { $0.id == record.id }) {
                var copy = selectedChannelMembers[idx]
                copy.notificationLevel = level
                selectedChannelMembers[idx] = copy
            }
            if let channelId = selectedChannel?.id {
                notificationLevelByChannel[channelId] = level
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archiveSelectedChannel() async {
        guard canManageSelectedChannel,
              let service, let workspace, let channel = selectedChannel else { return }
        do {
            _ = try await service.updateChannel(
                channelId: channel.id,
                workspaceId: workspace.id,
                name: nil,
                description: nil,
                visibility: nil,
                isArchived: true
            )
            channels.removeAll { $0.id == channel.id }
            directMessages.removeAll { $0.id == channel.id }
            selectedChannel = channels.first ?? directMessages.first
            showChannelSettings = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func replaceChannelInLists(_ channel: ChatChannel) {
        if let idx = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[idx] = channel
        }
        if let idx = directMessages.firstIndex(where: { $0.id == channel.id }) {
            directMessages[idx] = channel
        }
    }

    func selectChannelById(_ channelId: UUID, recordHistory: Bool = true) {
        let all = channels + directMessages
        guard let channel = all.first(where: { $0.id == channelId }) else { return }
        selectChannel(channel, recordHistory: recordHistory)
    }

    func refreshAfterReconnect() async {
        guard let workspace, let userId = currentUserId else { return }
        isOffline = false
        await loadWorkspaceData(workspaceId: workspace.id, userId: userId)
        startRealtime(workspaceId: workspace.id)
        if let channel = selectedChannel {
            await loadMessages(for: channel)
        }
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
        guard let service, let workspace, let channel = selectedChannel else { return }
        guard canPost(in: channel) else {
            errorMessage = "Only workspace admins can post in this channel."
            return
        }
        guard let userId = currentUserId else {
            errorMessage = "Your profile is still loading. Wait a moment or sign out and back in."
            return
        }
        let text = composerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if let parent = replyingTo {
            replyingTo = nil
            activeThreadParent = parent
            showThreadPanel = true
            threadComposerText = text
            composerText = ""
            await sendThreadReply()
            return
        }

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
            if let userId = currentUserId {
                await typingBroadcaster?.stopTyping(channelId: channel.id, userId: userId, displayName: displayName(for: userId))
            }
        } catch {
            if let idx = messages.firstIndex(where: { $0.id == optimisticId }) {
                var failed = messages[idx]
                failed.localStatus = .failed
                messages[idx] = failed
            }
            composerText = text
            errorMessage = error.localizedDescription
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

    func composerActivityChanged() {
        scheduleDraftSave()
        guard let channel = selectedChannel, let userId = currentUserId else { return }
        composerTypingTask?.cancel()
        composerTypingTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await typingBroadcaster?.sendTyping(
                channelId: channel.id,
                userId: userId,
                displayName: displayName(for: userId)
            )
        }
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

    func createChannel(
        name: String,
        visibility: ChatChannelVisibility = .public,
        description: String? = nil
    ) async {
        guard permissions.canCreateChannels else {
            errorMessage = "You do not have permission to create channels in this workspace."
            return
        }
        guard let service, let workspace, let userId = currentUserId else {
            errorMessage = "Sign in and select a workspace to create channels."
            return
        }
        let clean = name.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard !clean.isEmpty else { return }
        do {
            let ch = try await service.createChannel(
                workspaceId: workspace.id,
                name: clean,
                visibility: visibility,
                description: description,
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
        ChatUserPreferences.saveMyStatus(status)
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
        if userId == currentUserId { return myStatus }
        return presence[userId]?.status ?? .offline
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
        guard let auth else { return }
        typingBroadcaster = ChatTypingBroadcaster(client: auth.client, workspaceId: workspaceId)
        startTypingExpirySweep()
        let handler = IncomingMessageHandler(viewModel: self)
        service?.subscribeMessages(workspaceId: workspaceId, onInsert: handler.handleMessage)
        service?.subscribeMessageUpdates(
            workspaceId: workspaceId,
            onUpdate: handler.handleMessageUpdate,
            onDelete: handler.handleMessageDelete
        )
        service?.subscribePresence(workspaceId: workspaceId, onChange: handler.handlePresence)
        service?.subscribeReactions(workspaceId: workspaceId, onChange: handler.handleReactions)
    }

    private func subscribeTyping(for channelId: UUID) async {
        guard let typingBroadcaster else { return }
        typingListenTask?.cancel()
        await typingBroadcaster.configureHandlers(
            onTyping: { [weak self] cid, uid, name in
                Task { @MainActor [weak self] in
                    self?.mergeTypingUser(channelId: cid, userId: uid, displayName: name)
                }
            },
            onStop: { [weak self] cid, uid in
                Task { @MainActor [weak self] in
                    self?.removeTypingUser(channelId: cid, userId: uid)
                }
            }
        )
        await typingBroadcaster.subscribe(channelId: channelId)
    }

    func refreshDockBadge() {
        ChatNotificationService.shared.setBadgeCount(totalUnread)
    }

    private func startTypingExpirySweep() {
        typingExpiryTask?.cancel()
        typingExpiryTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    guard let self else { return }
                    let now = Date()
                    self.typingUsers = self.typingUsers.filter { $0.expiresAt > now }
                }
            }
        }
    }

    private func mergeTypingUser(channelId: UUID, userId: UUID, displayName: String) {
        guard selectedChannel?.id == channelId, userId != currentUserId else { return }
        var users = typingUsers.filter { $0.userId != userId && $0.expiresAt > Date() }
        users.append(
            ChatTypingState(
                channelId: channelId,
                userId: userId,
                displayName: displayName,
                expiresAt: Date().addingTimeInterval(4)
            )
        )
        typingUsers = users
    }

    private func removeTypingUser(channelId: UUID, userId: UUID) {
        guard selectedChannel?.id == channelId else { return }
        typingUsers.removeAll { $0.userId == userId }
    }

    func handleIncomingMessage(_ message: ChatMessage) {
        ChatWindowManager.shared.forwardIncomingMessage(message)

        if selectedChannel?.id == message.channelId {
            if message.userId == currentUserId,
               let idx = messages.firstIndex(where: {
                   $0.localStatus == .sending && $0.body == message.body && $0.channelId == message.channelId
               }) {
                var confirmed = message
                confirmed.localStatus = .sent
                messages[idx] = confirmed
            } else if !messages.contains(where: { $0.id == message.id }) {
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
            if message.threadParentId != nil {
                let t = (unreadThreadsByChannel[message.channelId] ?? 0) + 1
                unreadThreadsByChannel[message.channelId] = t
            }
            if message.userId != currentUserId {
                notifyForIncomingMessage(message)
            }
        }
        updateChannelPreview(message)
        refreshDockBadge()
    }

    func handleMessageUpdate(_ message: ChatMessage) {
        if selectedChannel?.id == message.channelId {
            if let idx = messages.firstIndex(where: { $0.id == message.id }) {
                messages[idx] = message
            }
            if let parent = message.threadParentId, activeThreadParent?.id == parent,
               let idx = threadMessages.firstIndex(where: { $0.id == message.id }) {
                threadMessages[idx] = message
            }
        }
        ChatWindowManager.shared.forwardMessageUpdate(message)
    }

    func handleMessageDelete(_ messageId: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == messageId }) {
            var m = messages[idx]
            m.isDeleted = true
            m.body = nil
            m.attachments = []
            messages[idx] = m
        }
        threadMessages.removeAll { $0.id == messageId }
        voiceTranscripts.removeValue(forKey: messageId)
        ChatWindowManager.shared.forwardMessageDelete(messageId)
    }

    private func notifyForIncomingMessage(_ message: ChatMessage) {
        guard message.userId != currentUserId else { return }
        guard !deliveredMacNotificationMessageIds.contains(message.id) else { return }
        guard shouldNotify(for: message) else { return }

        deliveredMacNotificationMessageIds.insert(message.id)
        if deliveredMacNotificationMessageIds.count > 500 {
            deliveredMacNotificationMessageIds = Set(deliveredMacNotificationMessageIds.suffix(200))
        }

        let channelName = (channels + directMessages).first { $0.id == message.channelId }?.displayTitle ?? "Chat"
        let author = displayName(for: message.userId)
        let preview = notificationPreview(for: message)
        let category = notificationCategory(for: message)

        appendInAppNotification(
            message: message,
            channelTitle: channelName,
            authorName: author,
            preview: preview,
            category: category
        )

        let deliverBanner = !ChatNotificationFocusState.shared.isViewingChannel(message.channelId)
        ChatNotificationService.shared.notify(
            title: category == .mention ? "Mention in \(channelName)" : channelName,
            body: "\(author): \(preview)",
            channelId: message.channelId,
            messageId: message.id,
            category: category,
            deliverBanner: deliverBanner
        )
    }

    private func shouldNotify(for message: ChatMessage) -> Bool {
        let level = notificationLevelByChannel[message.channelId] ?? "all"
        switch level {
        case "nothing", "mute":
            return false
        case "mentions":
            return messageMentionsCurrentUser(message)
        default:
            return true
        }
    }

    private func messageMentionsCurrentUser(_ message: ChatMessage) -> Bool {
        let body = message.body ?? ""
        let mentions = ChatMentionParser.parse(body, profiles: profiles)
        return mentions.contains { token in
            if token.type == .user, token.userId == currentUserId { return true }
            if token.type == .here || token.type == .channel { return true }
            return false
        }
    }

    private func notificationCategory(for message: ChatMessage) -> ChatNotificationCategory {
        messageMentionsCurrentUser(message) ? .mention : .message
    }

    private func notificationPreview(for message: ChatMessage) -> String {
        if let body = message.body?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty {
            return String(body.prefix(240))
        }
        if message.attachments.contains(where: \.isVoice) {
            return "Voice message"
        }
        if !message.attachments.isEmpty {
            return "Shared a file"
        }
        return "New message"
    }

    private func appendInAppNotification(
        message: ChatMessage,
        channelTitle: String,
        authorName: String,
        preview: String,
        category: ChatNotificationCategory
    ) {
        let item = ChatInAppNotification(
            messageId: message.id,
            channelId: message.channelId,
            channelTitle: channelTitle,
            authorName: authorName,
            body: preview,
            category: category,
            createdAt: message.createdAt
        )
        inAppNotifications.removeAll { $0.id == item.id }
        inAppNotifications.insert(item, at: 0)
        if inAppNotifications.count > maxInAppNotifications {
            inAppNotifications = Array(inAppNotifications.prefix(maxInAppNotifications))
        }
    }

    func markInAppNotificationsRead(for channelId: UUID) {
        let updated = inAppNotifications.map { item -> ChatInAppNotification in
            guard item.channelId == channelId, !item.isRead else { return item }
            var copy = item
            copy.isRead = true
            return copy
        }
        if updated != inAppNotifications {
            inAppNotifications = updated
        }
    }

    func markAllInAppNotificationsRead() {
        guard inAppNotifications.contains(where: { !$0.isRead }) else { return }
        inAppNotifications = inAppNotifications.map { item in
            var copy = item
            copy.isRead = true
            return copy
        }
    }

    var unreadInAppNotificationCount: Int {
        inAppNotifications.filter { !$0.isRead }.count
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

    // MARK: - Sidebar (ClickUp-style filters + layout)

    func setSidebarFilter(_ filter: ChatSidebarFilter) {
        sidebarFilter = filter
        ChatUserPreferences.saveSidebarFilter(filter)
    }

    func setSidebarLayout(_ layout: ChatSidebarLayout) {
        sidebarLayout = layout
        ChatUserPreferences.saveSidebarLayout(layout)
    }

    var filteredChannels: [ChatChannel] {
        sidebarChannelsList(channels)
    }

    var filteredDMs: [ChatChannel] {
        sidebarChannelsList(directMessages)
    }

    var sidebarRecentsList: [ChatChannel] {
        let combined = channels + directMessages
        let sorted = combined.sorted {
            ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
        }
        return sidebarChannelsList(sorted)
    }

    /// ClickUp-style pinned section — user-pinned channels/DMs (persisted per workspace).
    var pinnedSidebarChannels: [ChatChannel] {
        let all = channels + directMessages
        return all
            .filter { pinnedSidebarChannelIds.contains($0.id) }
            .sorted {
                $0.sidebarTitle.localizedCaseInsensitiveCompare($1.sidebarTitle) == .orderedAscending
            }
    }

    /// Legacy alias for bar-menu badge counts.
    var favoriteChannels: [ChatChannel] { pinnedSidebarChannels }

    var canPostInSelectedChannel: Bool {
        guard let channel = selectedChannel else { return false }
        switch channel.visibility {
        case .announcement, .readOnly:
            return permissions.canDeleteMessages || permissions.canPinMessages
        default:
            return true
        }
    }

    func reloadPinnedSidebarChannels() {
        guard let workspaceId = workspace?.id else {
            pinnedSidebarChannelIds = []
            return
        }
        pinnedSidebarChannelIds = ChatUserPreferences.loadPinnedChannelIds(workspaceId: workspaceId)
    }

    func toggleSidebarPin(for channel: ChatChannel) {
        guard let workspaceId = workspace?.id else { return }
        if pinnedSidebarChannelIds.contains(channel.id) {
            pinnedSidebarChannelIds.remove(channel.id)
        } else {
            pinnedSidebarChannelIds.insert(channel.id)
        }
        ChatUserPreferences.savePinnedChannelIds(pinnedSidebarChannelIds, workspaceId: workspaceId)
    }

    func isSidebarPinned(_ channel: ChatChannel) -> Bool {
        pinnedSidebarChannelIds.contains(channel.id)
    }

    func openFirstUnreadChannel() {
        let all = channels + directMessages
        if let ch = all.first(where: {
            unreadCount(for: $0.id) > 0 || hasUnreadThreadReplies(for: $0.id)
        }) {
            selectChannel(ch)
        } else if let first = all.first {
            selectChannel(first)
        }
    }

    func openPinnedSidebarFocus() {
        if let first = pinnedSidebarChannels.first {
            selectChannel(first)
        }
    }

    func openUnreadThreadFromSidebar(for channel: ChatChannel) async {
        selectChannel(channel)
        if let parent = mainChannelMessages.first(where: { (threadCounts[$0.id] ?? 0) > 0 }) {
            await openThread(for: parent)
        } else if hasUnreadThreadReplies(for: channel.id) {
            showThreadPanel = true
        }
    }

    var filteredProjects: [PlannerTask] {
        let q = sidebarSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return plannerTasks }
        return plannerTasks.filter {
            $0.title.lowercased().contains(q) || $0.status.lowercased().contains(q)
        }
    }

    func unreadCount(for channelId: UUID) -> Int {
        unreadByChannel[channelId] ?? 0
    }

    func hasUnreadThreadReplies(for channelId: UUID) -> Bool {
        (unreadThreadsByChannel[channelId] ?? 0) > 0
    }

    func isSidebarRowBold(_ channel: ChatChannel) -> Bool {
        unreadCount(for: channel.id) > 0 || hasUnreadThreadReplies(for: channel.id)
    }

    private func sidebarChannelsList(_ list: [ChatChannel]) -> [ChatChannel] {
        var result = list
        let q = sidebarSearchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(q)
                    || ($0.description?.lowercased().contains(q) ?? false)
                    || $0.sidebarTitle.lowercased().contains(q)
            }
        }
        switch sidebarFilter {
        case .all:
            break
        case .unread:
            result = result.filter {
                unreadCount(for: $0.id) > 0 || hasUnreadThreadReplies(for: $0.id)
            }
        case .dms:
            result = result.filter { $0.kind == .dm || $0.kind == .group }
        case .channels:
            result = result.filter { $0.kind == .channel }
        }
        if sidebarLayout == .recents {
            result.sort {
                ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
            }
        } else {
            result.sort {
                $0.sidebarTitle.localizedCaseInsensitiveCompare($1.sidebarTitle) == .orderedAscending
            }
        }
        return result
    }

    private func filter(_ list: [ChatChannel]) -> [ChatChannel] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return list }
        return list.filter { $0.name.lowercased().contains(q) || ($0.description?.lowercased().contains(q) ?? false) }
    }

    var totalUnread: Int {
        unreadByChannel.values.reduce(0, +) + unreadThreadsByChannel.values.reduce(0, +)
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

    func handleMessageUpdate(_ message: ChatMessage) {
        Task { @MainActor [weak viewModel] in
            viewModel?.handleMessageUpdate(message)
        }
    }

    func handleMessageDelete(_ messageId: UUID) {
        Task { @MainActor [weak viewModel] in
            viewModel?.handleMessageDelete(messageId)
        }
    }
}
