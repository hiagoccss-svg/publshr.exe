import SwiftUI

/// ClickUp-style hub tabs — text tabs with underline (Channels / Activity / Drafts / Sent).
struct ChatSidebarHubStrip: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChatSidebarHub.allCases) { hub in
                    hubTab(hub)
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .frame(height: ChatClickUpDesign.filterBarHeight, alignment: .bottom)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LibraryGlassDesign.contentDivider.opacity(0.55))
                .frame(height: 1)
                .padding(.horizontal, 12)
        }
    }

    private func hubTab(_ hub: ChatSidebarHub) -> some View {
        let selected = chat.sidebarHub == hub
        let badge = badgeCount(for: hub)
        return Button {
            chat.setSidebarHub(hub)
        } label: {
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Text(hub.label)
                        .font(.system(size: 12, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
                        .lineLimit(1)
                    if badge > 0 {
                        Text(badge > 99 ? "99+" : "\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(LibraryGlassDesign.primaryCTA)
                            .clipShape(Capsule())
                    }
                }
                Rectangle()
                    .fill(selected ? LibraryGlassDesign.ink : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }

    private func badgeCount(for hub: ChatSidebarHub) -> Int {
        switch hub {
        case .channels:
            return 0
        case .activity:
            return chat.unreadInAppNotificationCount
        case .drafts:
            return chat.draftSummaries.count
        case .sent:
            return 0
        }
    }
}

struct ChatActivityHubView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Activity")
            if chat.inAppNotifications.isEmpty {
                hubEmpty("No recent alerts — mentions and messages appear here.")
            } else {
                ForEach(chat.inAppNotifications) { item in
                    activityRow(item)
                }
            }
            Button {
                chat.markAllInAppNotificationsRead()
                chat.markAllChannelsRead()
            } label: {
                Label("Mark all read", systemImage: "checkmark.circle")
            }
            .buttonStyle(LibrarySubmenuTextButtonStyle())
            .padding(.top, 6)
        }
    }

    private func activityRow(_ item: ChatInAppNotification) -> some View {
        Button {
            if let channel = (chat.channels + chat.directMessages).first(where: { $0.id == item.channelId }) {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
                chat.setSidebarHub(.channels)
            }
        } label: {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.category == .mention ? "at" : "bubble.left.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(item.isRead ? LibraryGlassDesign.inkMuted : LibraryGlassDesign.primaryCTA)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.channelTitle)
                            .font(.system(size: 12, weight: item.isRead ? .regular : .semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Text(LibraryRelativeTime.string(since: item.createdAt) ?? "")
                            .font(.system(size: 10))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    Text("\(item.authorName): \(item.body)")
                        .font(.system(size: 11))
                        .foregroundStyle(LibraryGlassDesign.inkSecondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}

struct ChatDraftsHubView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Drafts")
            if chat.draftSummaries.isEmpty {
                hubEmpty("Drafts save automatically while you type.")
            } else {
                ForEach(chat.draftSummaries) { draft in
                    draftRow(draft)
                }
            }
        }
        .onAppear { chat.reloadDraftSummaries() }
    }

    private func draftRow(_ draft: ChatDraftSummary) -> some View {
        Button {
            if let channel = (chat.channels + chat.directMessages).first(where: { $0.id == draft.channelId }) {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
                chat.composerText = draft.body
                chat.setSidebarHub(.channels)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(draft.channelTitle)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer(minLength: 0)
                    Text(LibraryRelativeTime.string(since: draft.updatedAt) ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                Text(draft.body)
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}

struct ChatSentHubView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LibraryUniversalSubmenu.sectionHeader("Sent")
            if chat.sentSummaries.isEmpty {
                hubEmpty("Messages you send appear here.")
            } else {
                ForEach(chat.sentSummaries) { item in
                    sentRow(item)
                }
            }
            if !chat.scheduledMessages.isEmpty {
                LibraryUniversalSubmenu.sectionDivider()
                LibraryUniversalSubmenu.sectionHeader("Scheduled")
                ForEach(chat.scheduledMessages.filter(\.isPending)) { item in
                    scheduledRow(item)
                }
            }
        }
        .onAppear { Task { await chat.reloadSentSummaries(); await chat.reloadScheduledMessages() } }
    }

    private func sentRow(_ item: ChatSentMessageSummary) -> some View {
        Button {
            if let channel = (chat.channels + chat.directMessages).first(where: { $0.id == item.message.channelId }) {
                tabStore.openFromChannel(channel)
                chat.selectChannel(channel)
                chat.setSidebarHub(.channels)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.channelTitle)
                        .font(.system(size: 12, weight: .semibold))
                    Spacer(minLength: 0)
                    Text(LibraryRelativeTime.string(since: item.message.createdAt) ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                }
                Text(item.message.body ?? "Attachment")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .lineLimit(2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    private func scheduledRow(_ item: ChatScheduledMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.body)
                    .font(.system(size: 11))
                    .lineLimit(2)
                Text(scheduledLabel(item.sendAt))
                    .font(.system(size: 10))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            Spacer(minLength: 0)
            Button {
                Task { await chat.cancelScheduled(item) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private func scheduledLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return "Sends \(f.string(from: date))"
    }
}

private func hubEmpty(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 11))
        .foregroundStyle(LibraryGlassDesign.inkMuted)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
}
