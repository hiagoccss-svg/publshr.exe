import SwiftUI

/// Reference primary column (~200px): date, black CTA pill, labeled nav, disconnected bottom icons.
struct LibraryBarMenuColumn: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            dateBlock
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            primaryCTA
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            navDivider

            VStack(spacing: 3) {
                navRow("Chat", icon: "bubble.left.and.bubble.right", selected: module == .chat) {
                    switchModule(.chat)
                }
                navRow("Spaces", icon: "square.grid.2x2", selected: module == .spaces) {
                    switchModule(.spaces)
                }
                if module == .chat {
                    navRow(
                        "Inbox",
                        icon: "tray",
                        badge: min(chat.totalUnread, 99),
                        selected: false
                    ) {
                        openFirstUnread()
                    }
                    navRow(
                        "Saved",
                        icon: "bookmark",
                        badge: chat.starredChannels.count,
                        selected: false
                    ) {
                        if let fav = chat.starredChannels.first {
                            tabStore.openFromChannel(fav)
                            chat.selectChannel(fav)
                        }
                    }
                    navRow("Notes", icon: "note.text", selected: false) {
                        chat.setSidebarLayout(.organized)
                    }
                    navRow("Tasks", icon: "checklist", selected: false) {
                        module = .spaces
                        tabStore.openFromModule(.spaces, activate: true)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            Spacer(minLength: 0)

            bottomIcons
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
        .frame(width: LibraryGlassDesign.barMenuWidth)
        .frame(maxHeight: .infinity)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(2)
        .glassSidebar()
    }

    private var dateBlock: some View {
        let now = Date()
        return VStack(alignment: .leading, spacing: 4) {
            Text(now.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.ink)
            Text(now.formatted(.dateTime.month(.wide).day().year()))
                .font(.system(size: 12))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            HStack(spacing: 6) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                Text("Snow Flurries")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var primaryCTA: some View {
        switch module {
        case .chat:
            Button { showNewChannel = true } label: {
                Label("New message", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .spaces:
            Button { spaces.showNewSpaceSheet = true } label: {
                Label("New space", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .settings:
            EmptyView()
        }
    }

    private var navDivider: some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline)
            .frame(height: 1)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
    }

    private func navRow(
        _ title: String,
        icon: String,
        badge: Int = 0,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .frame(width: 20, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomIcons: some View {
        HStack {
            Button {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                Task { await auth.signOut() }
            } label: {
                Image(systemName: "arrow.right.to.line")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            .buttonStyle(.plain)
        }
    }

    private func switchModule(_ item: AppModule) {
        module = item
        tabStore.openFromModule(item, activate: true)
    }

    private func openFirstUnread() {
        tabStore.sidebarExpanded = true
        chat.setSidebarFilter(.unread)
        let all = chat.channels + chat.directMessages
        if let ch = all.first(where: {
            chat.unreadCount(for: $0.id) > 0 || chat.hasUnreadThreadReplies(for: $0.id)
        }) {
            tabStore.openFromChannel(ch)
            chat.selectChannel(ch)
        } else if let first = all.first {
            chat.setSidebarFilter(.all)
            tabStore.openFromChannel(first)
            chat.selectChannel(first)
        } else {
            chat.setSidebarFilter(.all)
            showNewDM = true
        }
    }
}
