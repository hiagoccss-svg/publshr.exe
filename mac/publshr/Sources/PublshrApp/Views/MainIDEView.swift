import SwiftUI

struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @State private var selectedActivity = 0

    var body: some View {
        VStack(spacing: 0) {
            AppUpdateBannerView(updates: updates)
            TitleBarView()
                .frame(height: CursorTheme.titleBarHeight)

            HStack(spacing: 0) {
                ActivityBarView(selection: $selectedActivity)
                    .frame(width: CursorTheme.activityBarWidth)

                SidebarView(selection: selectedActivity)
                    .frame(width: CursorTheme.sideBarWidth)

                Rectangle()
                    .fill(CursorTheme.border)
                    .frame(width: 1)

                EditorAreaView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Rectangle()
                    .fill(CursorTheme.border)
                    .frame(width: 1)

                EnterpriseChatView(chat: chat)
                    .frame(width: CursorTheme.chatPanelWidth)
                    .onAppear { chat.attach(auth: auth) }
                    .onDisappear { chat.detach() }
            }

            StatusBarView()
                .frame(height: CursorTheme.statusBarHeight)
        }
        .background(CursorTheme.editorBackground)
    }
}
