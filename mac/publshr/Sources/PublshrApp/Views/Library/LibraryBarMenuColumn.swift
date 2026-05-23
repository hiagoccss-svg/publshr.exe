import SwiftUI

/// Primary bar menu — enterprise operations (Dashboard, Spaces, Chat, Documents, …).
struct LibraryBarMenuColumn: View {
    var barWidth: CGFloat = LibraryGlassDesign.barMenuWidth
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @ObservedObject private var trafficLayout = TrafficLightLayoutStore.shared
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    private var bodyLeadingPadding: CGFloat {
        ShellBarColumnInset.bodyLeadingPadding(
            barWidth: barWidth,
            expanded: tabStore.barMenuExpanded,
            trafficLeadingInset: trafficLayout.leadingInset
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
                ForEach(SpacesEnterpriseSection.mainNav) { section in
                    navRow(
                        section.label,
                        icon: section.systemImage,
                        badge: section == .chat ? chatUnreadBadge : 0,
                        selected: isSectionSelected(section)
                    ) {
                        selectSection(section)
                    }
                }
            }
            .padding(.top, AppWindowChromeMetrics.barColumnBodyTopSpacing)
            .padding(.bottom, AppWindowChromeMetrics.toolbarItemSpacing)
            .padding(.leading, bodyLeadingPadding)
            .padding(.trailing, LibraryGlassDesign.barMenuRowHorizontal)

            Spacer(minLength: 0)

            LibraryBarMenuProfileFooter(profilePresentation: $profilePresentation)
                .padding(.leading, bodyLeadingPadding)
                .padding(.trailing, LibraryGlassDesign.barMenuRowHorizontal)
        }
        .frame(width: barWidth, alignment: .leading)
        .frame(minHeight: 0, maxHeight: .infinity)
    }

    private var chatUnreadBadge: Int {
        min(chat.totalUnread, 99)
    }

    private func isSectionSelected(_ section: SpacesEnterpriseSection) -> Bool {
        switch section {
        case .chat:
            return module == .chat
        case .media:
            return module == .mediaMonitoring
        case .whiteboard:
            return module.usesSpacesSubmenu && spaces.activeSection == .whiteboard
        default:
            return module.usesSpacesSubmenu && spaces.activeSection == section
        }
    }

    private func selectSection(_ section: SpacesEnterpriseSection) {
        tabStore.sidebarExpanded = true
        switch section {
        case .chat:
            module = .chat
            tabStore.openFromModule(.chat, activate: true)
        case .media:
            module = .mediaMonitoring
            tabStore.openFromModule(.mediaMonitoring, activate: true)
        case .whiteboard:
            module = .spaces
            tabStore.openFromModule(.spaces, activate: true)
            spaces.setActiveSection(.whiteboard)
            if spaces.selectedSpaceId == nil, let first = spaces.spaces.first {
                Task { await spaces.selectSpace(first.id) }
            }
        case .spaces:
            module = .spaces
            tabStore.openFromModule(.spaces, activate: true)
            spaces.openSpacesHome()
        case .planner:
            module = .spaces
            tabStore.openFromModule(.spaces, activate: true)
            spaces.openPlannerCalendar()
        default:
            module = .spaces
            tabStore.openFromModule(.spaces, activate: true)
            spaces.setActiveSection(section)
        }
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
            .frame(height: LibraryGlassDesign.barMenuRowHeight)
            .background(
                RoundedRectangle(cornerRadius: LibraryGlassDesign.sidebarRowRadius, style: .continuous)
                    .fill(selected ? LibraryGlassDesign.sidebarSelection : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
