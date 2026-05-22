import SwiftUI

struct ChatSidebarView: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    sidebarSection("Favorites", items: chat.favoriteChannels, onAdd: nil)
                    sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                    sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
                    projectsSection
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader("Projects", onAdd: nil)

            if chat.filteredProjects.isEmpty {
                Text("No planner tasks")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(chat.filteredProjects) { task in
                    Button {
                        Task { await chat.sharePlannerTask(task) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder")
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.system(size: 12))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                    .lineLimit(1)
                                Text(task.status)
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundDim)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(height: CursorTheme.chatSidebarRowHeight)
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                }
            }
        }
    }

    private func sidebarSection(
        _ title: String,
        items: [ChatChannel],
        onAdd: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader(title, onAdd: onAdd)

            if items.isEmpty {
                Text("None yet")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
            } else {
                ForEach(items) { channel in
                    channelRow(channel)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, onAdd: (() -> Void)?) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
                .tracking(0.5)
            Spacer()
            if let onAdd {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadByChannel[channel.id] ?? 0
        return Button {
            chat.selectChannel(channel)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: channel.sidebarIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                    .frame(width: 18)
                Text(dmTitle(channel))
                    .font(.system(size: 13, weight: unread > 0 ? .semibold : .regular))
                    .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if unread > 0 {
                    Text("\(unread)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CursorTheme.accent)
                        .clipShape(Capsule())
                }
            }
            .frame(height: CursorTheme.chatSidebarRowHeight)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selected ? CursorTheme.accent.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private func dmTitle(_ channel: ChatChannel) -> String {
        if channel.kind == .dm {
            return channel.description?.replacingOccurrences(of: "Direct message with ", with: "") ?? "Direct Message"
        }
        return channel.displayTitle
    }
}
