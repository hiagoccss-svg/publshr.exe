import SwiftUI

/// Primary column — enterprise section icons (collapsed bar).
struct LibraryBarMenuIconRail: View {
    var barWidth: CGFloat = ShellColumnLayout.barCollapsedMax
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @ObservedObject private var trafficLayout = TrafficLightLayoutStore.shared
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    private var trafficReserve: CGFloat {
        ShellBarColumnInset.trafficReserve(
            barWidth: barWidth,
            trafficLeadingInset: trafficLayout.leadingInset
        )
    }

    var body: some View {
        VStack(spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            ForEach(SpacesEnterpriseSection.mainNav) { section in
                sectionIcon(section)
            }
            Spacer(minLength: 0)

            Button {
                profilePresentation = .currentUser
            } label: {
                if let profile = auth.profile {
                    ChatProfileAvatar(
                        profile: profile,
                        displayName: profile.displayName ?? profile.email,
                        size: 30,
                        presence: chat.myStatus
                    )
                }
            }
            .buttonStyle(.plain)
            .help("Your profile")
            .padding(.bottom, 10)
        }
        .padding(.top, AppWindowChromeMetrics.barColumnBodyTopSpacing)
        .padding(.leading, trafficReserve)
        .padding(.trailing, 6)
        .frame(width: barWidth, alignment: .leading)
        .frame(maxHeight: .infinity)
    }

    private func sectionIcon(_ section: SpacesEnterpriseSection) -> some View {
        let selected = isSectionSelected(section)
        return Button {
            selectSection(section)
        } label: {
            TitlebarToolbarSlot {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .medium))
                        .foregroundStyle(selected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                        .frame(
                            width: AppWindowChromeMetrics.controlSize,
                            height: AppWindowChromeMetrics.controlSize
                        )
                        .background(
                            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                                .fill(selected ? MacSystemChrome.toolbarPressedFill : Color.clear)
                        )
                    if section == .chat, chat.totalUnread > 0 {
                        Text(chat.totalUnread > 99 ? "99+" : "\(chat.totalUnread)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(LibraryGlassDesign.ink.opacity(0.85)))
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .help(section.label)
    }

    private func isSectionSelected(_ section: SpacesEnterpriseSection) -> Bool {
        switch section {
        case .chat: return module == .chat
        case .media: return module == .mediaMonitoring
        case .whiteboard: return module.usesSpacesSubmenu && spaces.activeSection == .whiteboard
        default: return module.usesSpacesSubmenu && spaces.activeSection == section
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
}
