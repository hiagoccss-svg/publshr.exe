import SwiftUI

/// Full library-reference shell — desktop glass, 200px bar menu, universal submenu, floating main panel.
struct LibraryShellView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @Binding var module: AppModule
    @Binding var showNewChannel: Bool
    @Binding var showNewDM: Bool

    /// Avoid header/submenu jumping when safe-area insets settle after window chrome applies.
    @State private var stableTopInset: CGFloat = CursorTheme.windowChromeTopInset

    private var submenuHidden: Bool {
        !tabStore.sidebarExpanded
            || (module == .chat && chat.chatFocusMode)
            || (module == .spaces && spaces.spacesFocusMode)
    }

    var body: some View {
        GeometryReader { geometry in
            let topSafe = geometry.safeAreaInsets.top
            ZStack {
                WorkspaceDesktopBackdrop()

                VStack(spacing: 0) {
                    LibraryShellHeaderView(
                        spaces: spaces,
                        module: $module,
                        safeAreaTop: stableTopInset
                    )

                    HStack(alignment: .top, spacing: 0) {
                        LibraryBarMenuColumn(
                            module: $module,
                            showNewChannel: $showNewChannel,
                            showNewDM: $showNewDM
                        )

                        if !submenuHidden {
                            AppSecondarySidebar(
                                module: module,
                                chat: chat,
                                spaces: spaces,
                                showNewChannel: $showNewChannel,
                                showNewDM: $showNewDM
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }

                        mainStage
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.15), value: submenuHidden)

                    shellStatusLine
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if topSafe > 0 { stableTopInset = topSafe }
            }
            .onChange(of: topSafe) { _, newValue in
                guard newValue > 0, abs(newValue - stableTopInset) > 0.5 else { return }
                withAnimation(.easeInOut(duration: 0.12)) {
                    stableTopInset = newValue
                }
            }
        }
        .background(Color.clear)
    }

    private var mainStage: some View {
        moduleContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .libraryFloatingPanel()
            .padding(.horizontal, LibraryGlassDesign.outerMargin)
            .padding(.vertical, 12)
            .background(Color.clear)
    }

    @ViewBuilder
    private var moduleContent: some View {
        switch module {
        case .chat:
            if subscription.canUseChat(workspace: auth.selectedWorkspace) {
                EnterpriseChatView(chat: chat, topInset: 0)
            } else {
                EnterpriseModuleGate(moduleName: "Chat", planName: subscription.features.planName)
            }
        case .spaces:
            if subscription.canUseSpaces(workspace: auth.selectedWorkspace) {
                SpacesRootView(spaces: spaces, topInset: 0)
            } else {
                EnterpriseModuleGate(moduleName: "Spaces", planName: subscription.features.planName)
            }
        case .settings:
            EnterpriseModuleGate(moduleName: "Settings", planName: subscription.features.planName)
        }
    }

    private var shellStatusLine: some View {
        HStack(spacing: 10) {
            Text(updates.statusLine)
                .font(.system(size: 10))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            Text("·")
                .foregroundStyle(LibraryGlassDesign.inkMuted.opacity(0.5))
            Text(AppShellIdentity.distributionTag)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkSecondary)
            Spacer()
            if let email = auth.profile?.email {
                Text(email)
                    .font(.system(size: 10))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, LibraryGlassDesign.outerMargin + 4)
        .padding(.vertical, 6)
        .background(Color.clear)
    }
}
