import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel

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
            syncEnterpriseData()
        }
        .onChange(of: auth.flowState) { _, _ in
            applyAppearance()
            syncEnterpriseData()
        }
        .onChange(of: auth.selectedMembership?.id) { _, _ in
            syncEnterpriseData()
        }
        .task(id: auth.flowState) {
            guard auth.flowState == .signedIn else { return }
            await runPeriodicSupabaseSync()
        }
    }

    private var bootstrappingView: some View {
        ZStack {
            CursorTheme.activityBar.ignoresSafeArea()
            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.regular)
                Text("Restoring your session…")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
    }

    private func applyAppearance() {
        switch auth.flowState {
        case .signedIn:
            CursorTheme.appearance = .light
        case .bootstrapping, .signedOut, .confirmEmail, .selectWorkspace:
            CursorTheme.appearance = .light
        }
    }

    /// Pull Chat + Spaces from Supabase whenever workspace/session is ready — no status-bar clicks.
    private func syncEnterpriseData() {
        guard auth.flowState == .signedIn else { return }
        chat.attach(auth: auth)
        chat.applyWorkspaceContext(
            workspace: auth.selectedWorkspace,
            permissions: auth.workspaceChatPermissions,
            auth: auth
        )
        spaces.attach(auth: auth)
    }

    private func runPeriodicSupabaseSync() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            guard auth.flowState == .signedIn else { continue }
            await chat.refreshAfterReconnect()
            await spaces.reload()
            await chat.loadPlannerTasks()
        }
    }
}
