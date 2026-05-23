import SwiftUI

/// Primary column — enterprise module icons only (52px), below the traffic-light header band.
struct LibraryBarMenuIconRail: View {
    var barWidth: CGFloat = ShellColumnLayout.barCollapsedMax
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        VStack(spacing: AppWindowChromeMetrics.toolbarItemSpacing) {
            ForEach(AppModule.mainStrip) { item in
                moduleIcon(item)
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
        .padding(.top, 8)
        .padding(.horizontal, 6)
        .frame(width: barWidth, alignment: .center)
        .frame(maxHeight: .infinity)
    }

    private func moduleIcon(_ item: AppModule) -> some View {
        let selected = module == item
        return Button {
            module = item
            tabStore.openFromModule(item, activate: true)
            if item == .whiteboard {
                spaces.taskView = .whiteboard
                if spaces.selectedSpaceId == nil, let first = spaces.spaces.first {
                    Task { await spaces.selectSpace(first.id) }
                }
            }
            if item == .mediaMonitoring {
                _ = DesktopCompanionAppLauncher.open(.mediaMonitoring)
            }
        } label: {
            TitlebarToolbarSlot {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.systemImage)
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
                    if item == .chat, chat.totalUnread > 0 {
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
        .help(item.label)
    }
}
