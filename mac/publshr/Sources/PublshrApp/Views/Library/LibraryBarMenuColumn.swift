import SwiftUI

/// Primary bar menu — app modules only (Chat, Spaces).
struct LibraryBarMenuColumn: View {
    var barWidth: CGFloat = LibraryGlassDesign.barMenuWidth
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 3) {
                ForEach(AppModule.mainStrip) { item in
                    navRow(
                        item.label,
                        icon: item.systemImage,
                        badge: item == .chat ? chatUnreadBadge : 0,
                        selected: module == item
                    ) {
                        switchModule(item)
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 8)

            Spacer(minLength: 0)

            LibraryBarMenuProfileFooter(profilePresentation: $profilePresentation)
        }
        .frame(width: barWidth, alignment: .leading)
        .frame(minHeight: 0, maxHeight: .infinity)
    }

    private var chatUnreadBadge: Int {
        min(chat.totalUnread, 99)
    }

    private func navRow(
        _ title: String,
        icon: String,
        badge: Int = 0,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .regular))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                Text(title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                if badge > 0 {
                    Text(badge > 99 ? "99+" : "\(badge)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(LibraryGlassDesign.primaryCTA)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, LibraryGlassDesign.barMenuRowHorizontal)
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection.opacity(0.72) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func switchModule(_ item: AppModule) {
        module = item
        tabStore.openFromModule(item, activate: true)
        if item == .chat || item.usesSpacesSubmenu {
            tabStore.sidebarExpanded = true
        }
        if item == .whiteboard {
            spaces.taskView = .whiteboard
            if spaces.selectedSpaceId == nil, let first = spaces.spaces.first {
                Task { await spaces.selectSpace(first.id) }
            }
        }
        if item == .mediaMonitoring {
            _ = DesktopCompanionAppLauncher.open(.mediaMonitoring)
        }
    }
}
