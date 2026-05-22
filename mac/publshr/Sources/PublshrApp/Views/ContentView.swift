import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel

    var body: some View {
        Group {
            switch auth.flowState {
            case .bootstrapping:
                bootstrappingView
            case .signedOut, .confirmEmail:
                AuthView()
            case .selectWorkspace:
                WorkspacePickerView()
            case .signedIn:
                MainIDEView()
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(CursorTheme.editorBackground)
        .preferredColorScheme(CursorTheme.appearance == .light ? .light : .dark)
        .onAppear {
            applyAppearance()
            syncChatWorkspace()
        }
        .onChange(of: auth.flowState) { _, _ in
            applyAppearance()
            syncChatWorkspace()
        }
        .onChange(of: auth.selectedMembership?.id) { _, _ in
            syncChatWorkspace()
        }
    }

    private var bootstrappingView: some View {
        ZStack {
            CursorTheme.authBackground.ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                Text("Loading Publshr…")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
        .preferredColorScheme(.light)
    }

    private func applyAppearance() {
        switch auth.flowState {
        case .signedIn:
            CursorTheme.appearance = .light
        case .bootstrapping, .signedOut, .confirmEmail, .selectWorkspace:
            CursorTheme.appearance = .light
        }
    }

    private func syncChatWorkspace() {
        guard auth.flowState == .signedIn else { return }
        chat.applyWorkspaceContext(
            workspace: auth.selectedWorkspace,
            permissions: auth.workspaceChatPermissions,
            auth: auth
        )
    }
}
