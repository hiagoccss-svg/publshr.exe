import SwiftUI

/// Primary bar menu — reference layout: ~200px labeled column (date, CTA, nav, disconnected bottom).
struct ActivityBarView: View {
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    var body: some View {
        VStack(spacing: 0) {
            dateWeatherWidget
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            primaryCTA
                .padding(.horizontal, 14)
                .padding(.bottom, 12)

            Rectangle()
                .fill(LibraryGlassDesign.hairline)
                .frame(height: 1)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            VStack(spacing: 4) {
                ForEach(AppModule.mainStrip) { item in
                    moduleButton(item)
                }
                if module == .chat {
                    barQuickRow(
                        title: "Inbox",
                        icon: "tray",
                        badge: min(chat.totalUnread, 99),
                        selected: false
                    ) {
                        openFirstUnreadChannel()
                    }
                    barQuickRow(
                        title: "Saved",
                        icon: "bookmark",
                        badge: chat.favoriteChannels.count,
                        selected: false
                    ) {
                        if let first = chat.favoriteChannels.first {
                            tabStore.openFromChannel(first)
                            chat.selectChannel(first)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 0)

            disconnectedBottomActions
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
        .frame(width: LibraryGlassDesign.barMenuWidth)
        .glassSidebar()
    }

    @ViewBuilder
    private var primaryCTA: some View {
        switch module {
        case .chat:
            Button {
                showNewChannel = true
            } label: {
                Label("New message", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .spaces:
            Button {
                spaces.showNewSpaceSheet = true
            } label: {
                Label("New space", systemImage: "plus")
            }
            .buttonStyle(LibraryPrimaryPillButtonStyle())
        case .settings:
            EmptyView()
        }
    }

    private var dateWeatherWidget: some View {
        let now = Date()
        return VStack(alignment: .leading, spacing: 4) {
            Text(now.formatted(.dateTime.weekday(.wide)))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LibraryGlassDesign.ink)
            Text(now.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: 11))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            HStack(spacing: 5) {
                Image(systemName: "cloud.sun")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moduleButton(_ item: AppModule) -> some View {
        barQuickRow(
            title: item.label,
            icon: item.systemImage,
            badge: 0,
            selected: module == item
        ) {
            module = item
            tabStore.openFromModule(item, activate: true)
        }
    }

    private func barQuickRow(
        title: String,
        icon: String,
        badge: Int,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, LibraryGlassDesign.sidebarRowHorizontal)
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openFirstUnreadChannel() {
        let channels = chat.filteredChannels + chat.filteredDMs
        if let unread = channels.first(where: { chat.unreadCount(for: $0.id) > 0 }) {
            tabStore.openFromChannel(unread)
            chat.selectChannel(unread)
            return
        }
        if let first = channels.first {
            tabStore.openFromChannel(first)
            chat.selectChannel(first)
        } else {
            showNewDM = true
        }
    }

    private var disconnectedBottomActions: some View {
        HStack(spacing: 0) {
            Button {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            } label: {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkSecondary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer(minLength: 0)

            Button {
                Task { await auth.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Sign out")
        }
    }
}
