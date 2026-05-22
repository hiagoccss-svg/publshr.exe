import SwiftUI

struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @State private var module: AppModule = .chat

    var body: some View {
        VStack(spacing: 0) {
            AppUpdateBannerView(updates: updates)
            TitleBarView(module: module)
                .frame(height: CursorTheme.titleBarHeight)

            HStack(spacing: 0) {
                ActivityBarView(module: $module)
                    .frame(width: CursorTheme.activityBarWidth)

                moduleWorkspace
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            StatusBarView(module: module)
                .frame(height: CursorTheme.statusBarHeight)
        }
        .background(CursorTheme.editorBackground)
        .onAppear {
            chat.attach(auth: auth)
        }
        .onChange(of: module) { _, newModule in
            if newModule == .chat {
                chat.attach(auth: auth)
            }
        }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            if module == .spaces {
                spaces.attach(auth: auth)
            }
        }
    }

    @ViewBuilder
    private var moduleWorkspace: some View {
        switch module {
        case .chat:
            EnterpriseChatView(chat: chat)
                .onAppear { chat.attach(auth: auth) }
        case .spaces:
            SpacesRootView(spaces: spaces)
        case .settings:
            SettingsView()
        }
    }
}
