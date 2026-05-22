import SwiftUI

/// Notifications drawer — live feed from realtime messages + unread summary.
struct TitlebarNotificationsPanelView: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool

    private var unreadChannels: [(ChatChannel, Int)] {
        let all = chat.channels + chat.directMessages
        return all.compactMap { ch -> (ChatChannel, Int)? in
            let n = chat.unreadCount(for: ch.id)
            return n > 0 ? (ch, n) : nil
        }
        .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if !chat.inAppNotifications.isEmpty {
                recentSection
            } else if unreadChannels.isEmpty {
                emptyState
            }

            if !unreadChannels.isEmpty {
                unreadSection
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            Task { await ChatNotificationService.shared.requestAuthorizationIfNeeded() }
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Notifications")
                .font(.system(size: 15, weight: .semibold))
            if chat.unreadInAppNotificationCount > 0 {
                Text("\(chat.unreadInAppNotificationCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(LibraryGlassDesign.primaryCTA))
            }
            Spacer()
            if chat.unreadInAppNotificationCount > 0 {
                Button("Mark all read") {
                    chat.markAllInAppNotificationsRead()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
            }
            Button("Done") { isPresented = false }
                .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        Text("You're all caught up.")
            .font(.system(size: 13))
            .foregroundStyle(LibraryGlassDesign.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(chat.inAppNotifications) { item in
                        notificationRow(item)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
    }

    private var unreadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Unread channels")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(unreadChannels, id: \.0.id) { channel, count in
                        Button {
                            chat.selectChannel(channel)
                            isPresented = false
                        } label: {
                            HStack {
                                Text(channel.displayTitle)
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(CursorTheme.accent))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 140)
        }
    }

    private func notificationRow(_ item: ChatInAppNotification) -> some View {
        Button {
            if let channel = (chat.channels + chat.directMessages).first(where: { $0.id == item.channelId }) {
                chat.selectChannel(channel)
                isPresented = false
            } else {
                chat.selectChannelById(item.channelId)
                isPresented = false
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(item.isRead ? LibraryGlassDesign.contentDivider : CursorTheme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.channelTitle)
                            .font(.system(size: 12, weight: item.isRead ? .regular : .semibold))
                            .foregroundStyle(LibraryGlassDesign.ink)
                        Spacer()
                        if let time = LibraryRelativeTime.string(since: item.createdAt) {
                            Text(time)
                                .font(.system(size: 10))
                                .foregroundStyle(LibraryGlassDesign.inkMuted)
                        }
                    }
                    Text("\(item.authorName): \(item.body)")
                        .font(.system(size: 12))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                item.isRead
                    ? Color.clear
                    : LibraryGlassDesign.sidebarSelection.opacity(0.35)
            )
        }
        .buttonStyle(.plain)
    }
}
