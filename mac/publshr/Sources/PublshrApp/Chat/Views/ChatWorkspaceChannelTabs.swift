import SwiftUI

/// ClickUp-style open channel tabs above the conversation column.
struct ChatWorkspaceChannelTabs: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel

    private var chatTabs: [WorkspaceTab] {
        tabStore.tabs.filter { tab in
            switch tab.kind {
            case .chatChannel, .chatDirectMessage:
                return true
            default:
                return false
            }
        }
    }

    var body: some View {
        if chatTabs.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(chatTabs) { tab in
                        tabChip(tab)
                    }
                }
                .padding(.horizontal, CursorMacShellDesign.editorHorizontalPadding)
                .padding(.vertical, 6)
            }
            .frame(maxWidth: .infinity)
            .background(CursorMacShellDesign.editorBoxBackground)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CursorMacShellDesign.borderSubtle)
                    .frame(height: 1)
            }
        }
    }

    private func tabChip(_ tab: WorkspaceTab) -> some View {
        let selected = tabStore.selectedTabId == tab.id
        return HStack(spacing: 0) {
            ChromeDocumentTab(
                title: tab.title,
                isSelected: selected,
                canClose: chatTabs.count > 1,
                onSelect: { activate(tab) },
                onClose: { tabStore.closeTab(id: tab.id) }
            )
            if selected, unreadBadge(for: tab) > 0 {
                Text(unreadBadge(for: tab) > 99 ? "99+" : "\(unreadBadge(for: tab))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(LibraryGlassDesign.primaryCTA)
                    .clipShape(Capsule())
                    .offset(x: -8, y: -10)
            }
        }
    }

    private func unreadBadge(for tab: WorkspaceTab) -> Int {
        let channelId: UUID? = switch tab.kind {
        case .chatChannel(let id), .chatDirectMessage(let id):
            id
        default:
            nil
        }
        guard let channelId else { return 0 }
        return chat.unreadCount(for: channelId) + (chat.hasUnreadThreadReplies(for: channelId) ? 1 : 0)
    }

    private func activate(_ tab: WorkspaceTab) {
        tabStore.selectedTabId = tab.id
        switch tab.kind {
        case .chatChannel(let id), .chatDirectMessage(let id):
            chat.selectChannelById(id, recordHistory: true)
        default:
            break
        }
    }
}
