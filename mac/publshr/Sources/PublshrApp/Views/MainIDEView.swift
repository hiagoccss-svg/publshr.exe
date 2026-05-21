import SwiftUI

struct MainIDEView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @State private var selectedActivity = 0
    @State private var chatInput = ""

    var body: some View {
        VStack(spacing: 0) {
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

                ChatPanelView(input: $chatInput)
                    .frame(width: CursorTheme.chatPanelWidth)
            }

            StatusBarView()
                .frame(height: CursorTheme.statusBarHeight)
        }
        .background(CursorTheme.editorBackground)
    }
}
