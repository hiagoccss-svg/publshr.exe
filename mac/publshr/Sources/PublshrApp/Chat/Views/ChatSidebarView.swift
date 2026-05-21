import SwiftUI

struct ChatSidebarView: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundDim)
                TextField("Search chats", text: $chat.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(10)
            .background(CursorTheme.inputBackground.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 10)
            .padding(.top, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    sidebarSection("Direct Messages", items: chat.filteredDMs, onAdd: { showNewDM = true })
                    sidebarSection("Channels", items: chat.filteredChannels, onAdd: { showNewChannel = true })
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 200)
        .background(CursorTheme.sideBar.opacity(0.6))
        .overlay(alignment: .trailing) {
            Rectangle().fill(CursorTheme.border).frame(width: 1)
        }
    }

    private func sidebarSection(
        _ title: String,
        items: [ChatChannel],
        onAdd: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .tracking(0.6)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if items.isEmpty {
                Text("None yet")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            } else {
                ForEach(items) { channel in
                    channelRow(channel)
                }
            }
        }
    }

    private func channelRow(_ channel: ChatChannel) -> some View {
        let selected = chat.selectedChannel?.id == channel.id
        let unread = chat.unreadByChannel[channel.id] ?? 0
        return Button {
            chat.selectChannel(channel)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: channel.sidebarIcon)
                    .font(.system(size: 12))
                    .foregroundStyle(selected ? CursorTheme.accent : CursorTheme.foregroundMuted)
                    .frame(width: 16)
                Text(dmTitle(channel))
                    .font(.system(size: 12, weight: unread > 0 ? .semibold : .regular))
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
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? CursorTheme.editorLineHighlight : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
    }

    private func dmTitle(_ channel: ChatChannel) -> String {
        if channel.kind == .dm {
            return channel.description?.replacingOccurrences(of: "Direct message with ", with: "") ?? "Direct Message"
        }
        return channel.displayTitle
    }
}
