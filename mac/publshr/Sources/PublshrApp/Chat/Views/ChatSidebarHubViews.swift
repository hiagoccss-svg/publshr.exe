import SwiftUI

/// ClickUp-style hub tabs — horizontal pills above channel lists (consistent across hubs).
struct ChatSidebarHubStrip: View {
    @ObservedObject var chat: ChatViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChatSidebarHub.allCases) { hub in
                    hubPill(hub)
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .padding(.vertical, 4)
        }
        .frame(height: ChatClickUpDesign.filterBarHeight, alignment: .center)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LibraryGlassDesign.contentDivider.opacity(0.55))
                .frame(height: 1)
                .padding(.horizontal, 12)
        }
    }

    private func hubPill(_ hub: ChatSidebarHub) -> some View {
        let selected = chat.sidebarHub == hub
        let badge = badgeCount(for: hub)
        return Button {
            chat.setSidebarHub(hub)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: hub.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(hub.label)
                    .font(.system(size: 11, weight: selected ? .semibold : .medium))
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
            .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
            .padding(.horizontal, ChatClickUpDesign.filterPillHPadding)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : LibraryGlassDesign.filterPillInactiveFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        selected ? LibraryGlassDesign.sidebarSelectionStroke : LibraryGlassDesign.filterPillInactiveStroke,
                        lineWidth: 1
                    )
            )
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
