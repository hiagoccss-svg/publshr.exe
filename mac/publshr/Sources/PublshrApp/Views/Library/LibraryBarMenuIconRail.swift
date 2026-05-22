import SwiftUI

/// Collapsed primary column (~52px) — module icons only when the bar menu is minimized.
struct LibraryBarMenuIconRail: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var tabStore: WorkspaceTabStore
    @EnvironmentObject private var chat: ChatViewModel
    @Binding var module: AppModule
    @Binding var profilePresentation: WorkspaceProfilePresentation?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(AppModule.mainStrip) { item in
                Button {
                    module = item
                    tabStore.openFromModule(item, activate: true)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(module == item ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(module == item ? LibraryGlassDesign.sidebarSelection : Color.clear)
                            )
                        if item == .chat, chat.totalUnread > 0 {
                            Text(chat.totalUnread > 99 ? "99+" : "\(chat.totalUnread)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(LibraryGlassDesign.primaryCTA)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(item.label)
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
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .frame(width: CursorMacShellDesign.barMenuIconRailWidth)
        .frame(maxHeight: .infinity)
    }
}
