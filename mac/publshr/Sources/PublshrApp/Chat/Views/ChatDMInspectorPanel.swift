import SwiftUI

/// ClickUp-style DM / group details — members, presence, notification level.
struct ChatDMInspectorPanel: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    membersSection
                    if let channel = chat.selectedChannel {
                        notificationSection(channel)
                    }
                    actionsSection
                }
                .padding(12)
            }
        }
        .frame(width: 260)
        .background(CursorMacShellDesign.editorColumnBackground)
        .overlay(alignment: .leading) {
            Rectangle().fill(CursorMacShellDesign.borderSubtle).frame(width: 1)
        }
    }

    private var header: some View {
        HStack {
            if let channel = chat.selectedChannel {
                ChatChannelIconView(channel: channel, size: 20)
                Text(channel.sidebarTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                chat.showDMInspector = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Members")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            if chat.selectedChannelMembers.isEmpty {
                Text("Loading…")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
            } else {
                ForEach(chat.selectedChannelMembers) { member in
                    memberRow(member)
                }
            }
        }
    }

    private func memberRow(_ member: ChatChannelMember) -> some View {
        let profile = chat.profile(for: member.userId)
        let name = chat.displayName(for: member.userId)
        return HStack(spacing: 8) {
            ChatProfileAvatar(
                profile: profile,
                displayName: name,
                size: 28,
                presence: chat.presence(for: member.userId)
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                Text(chat.presenceDetail(for: member.userId))
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }

    private func notificationSection(_ channel: ChatChannel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notifications")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            HStack(spacing: 6) {
                notifyChip("All", level: "all", channel: channel)
                notifyChip("Mentions", level: "mentions", channel: channel)
                notifyChip("Mute", level: "muted", channel: channel)
            }
        }
    }

    private func notifyChip(_ label: String, level: String, channel: ChatChannel) -> some View {
        Button {
            Task {
                chat.selectChannel(channel, recordHistory: false)
                await chat.setSelectedChannelNotificationLevel(level)
            }
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CursorTheme.inputBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Actions")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            if let channel = chat.selectedChannel {
                Button {
                    chat.copyChannelLink(channel)
                } label: {
                    Label("Copy link", systemImage: "link")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Button {
                    chat.markChannelUnread(channel)
                } label: {
                    Label("Mark unread", systemImage: "envelope.badge")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Button {
                    chat.showChannelSettings = true
                } label: {
                    Label("Conversation settings", systemImage: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
