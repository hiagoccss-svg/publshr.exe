import SwiftUI

/// Slack-style channel settings — members, visibility, notifications, archive.
struct ChatChannelSettingsSheet: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var channelName = ""
    @State private var channelDescription = ""
    @State private var visibility: ChatChannelVisibility = .public
    @State private var notificationLevel = "all"
    private var channel: ChatChannel? { chat.selectedChannel }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let channel, channel.kind != .dm {
                        aboutSection(channel)
                    }
                    membersSection
                    notificationsSection
                    if chat.canManageSelectedChannel, channel?.kind != .dm {
                        dangerSection
                    }
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 440, height: 520)
        .macNativeSheetPresentation()
        .onAppear(perform: syncFromChannel)
        .onChange(of: chat.selectedChannel?.id) { _, _ in syncFromChannel() }
    }

    private var header: some View {
        HStack {
            Text(channel?.displayTitle ?? "Channel settings")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func aboutSection(_ channel: ChatChannel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            TextField("Channel name", text: $channelName)
                .textFieldStyle(.roundedBorder)
                .disabled(!chat.canManageSelectedChannel)
            TextField("Description", text: $channelDescription, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
                .disabled(!chat.canManageSelectedChannel)
            if chat.canManageSelectedChannel {
                Picker("Visibility", selection: $visibility) {
                    ForEach(visibleOptions, id: \.self) { vis in
                        Text(vis.label).tag(vis)
                    }
                }
                .pickerStyle(.menu)
            } else {
                LabeledContent("Visibility", value: channel.visibility.label)
            }
        }
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Members (\(chat.selectedChannelMembers.count))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Spacer()
                if chat.canManageSelectedChannel, chat.permissions.canInviteUsers, channel?.kind != .dm {
                    memberInviteMenu
                }
            }
            if chat.selectedChannelMembers.isEmpty {
                Text("Loading members…")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            } else {
                ForEach(chat.selectedChannelMembers) { member in
                    memberRow(member)
                }
            }
        }
    }

    private var memberInviteMenu: some View {
        Menu {
            ForEach(invitableProfiles, id: \.id) { profile in
                Button {
                    Task { await chat.inviteMemberToSelectedChannel(profile: profile) }
                } label: {
                    Text(profile.displayName ?? profile.email)
                }
            }
        } label: {
            Label("Add people", systemImage: "person.badge.plus")
                .font(.system(size: 12, weight: .medium))
        }
        .menuStyle(.borderlessButton)
    }

    private func memberRow(_ member: ChatChannelMember) -> some View {
        let profile = chat.profile(for: member.userId)
        let name = profile?.displayName ?? profile?.email ?? "Member"
        let isSelf = member.userId == chat.currentUserId
        let canRemove = isSelf || chat.canManageSelectedChannel

        return HStack(spacing: 10) {
            ChatProfileAvatar(
                profile: profile,
                displayName: name,
                size: 32,
                presence: chat.presence(for: member.userId)
            )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                    if isSelf {
                        Text("(you)")
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                    }
                }
                Text(chat.presenceDetail(for: member.userId))
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .lineLimit(2)
            }
            Spacer()
            if canRemove, channel?.kind != .dm || isSelf {
                Button(role: .destructive) {
                    Task { await chat.removeMemberFromSelectedChannel(member) }
                } label: {
                    Text(isSelf ? "Leave" : "Remove")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Picker("Notify me", selection: $notificationLevel) {
                Text("All messages").tag("all")
                Text("Mentions only").tag("mentions")
                Text("Mute").tag("muted")
            }
            .pickerStyle(.segmented)
            .onChange(of: notificationLevel) { _, level in
                Task { await chat.setSelectedChannelNotificationLevel(level) }
            }
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Danger zone")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.error)
            Button("Archive channel", role: .destructive) {
                Task { await chat.archiveSelectedChannel() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var footer: some View {
        HStack {
            Button("Workspace chat permissions") {
                chat.showChannelSettings = false
                chat.showPermissionsSheet = true
            }
            .font(.system(size: 12))
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
            if chat.canManageSelectedChannel, channel?.kind != .dm {
                Button("Save") {
                    Task {
                        await chat.updateSelectedChannelSettings(
                            name: channelName.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: channelDescription.isEmpty ? nil : channelDescription,
                            visibility: visibility
                        )
                        dismiss()
                    }
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(16)
    }

    private var visibleOptions: [ChatChannelVisibility] {
        [.public, .private, .internal, .clientSafe, .announcement, .readOnly]
    }

    private var invitableProfiles: [Profile] {
        chat.profiles.values
            .filter { profile in
                profile.id != chat.currentUserId
                    && !chat.selectedChannelMembers.contains(where: { $0.userId == profile.id })
            }
            .sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }
    }

    private func syncFromChannel() {
        guard let channel else { return }
        channelName = channel.name.hasPrefix("#") ? String(channel.name.dropFirst()) : channel.name
        channelDescription = channel.description ?? ""
        visibility = channel.visibility
        notificationLevel = chat.myChannelMemberRecord()?.notificationLevel ?? "all"
        Task { await chat.loadChannelMembers(for: channel) }
    }
}
