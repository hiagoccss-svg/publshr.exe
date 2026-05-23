import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService

    @State private var showEnterpriseOnboarding = false

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
        .frame(minWidth: 1280, maxWidth: .infinity, minHeight: 760, maxHeight: .infinity)
        .background(Color.clear)
        .preferredColorScheme(.light)
        .onAppear {
            applyAppearance()
            syncEnterpriseData()
            evaluateOnboarding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrRestoreMainWindow)) { _ in
            openWindow(id: "main")
            DispatchQueue.main.async {
                MainWindowPresenter.restoreMainWindow()
            }
        }
        .onChange(of: auth.flowState) { _, _ in
            applyAppearance()
            syncEnterpriseData()
            evaluateOnboarding()
        }
        .onChange(of: auth.selectedMembership?.id) { _, _ in
            syncEnterpriseData()
            NotificationCenter.default.post(name: .publshrPerformCloudSync, object: nil)
        }
        .onChange(of: auth.profile?.avatarUrl) { _, _ in
            if let profile = auth.profile {
                chat.upsertProfile(profile)
            }
        }
        .sheet(isPresented: $showEnterpriseOnboarding) {
            EnterpriseOnboardingView(isPresented: $showEnterpriseOnboarding)
        }
        .sheet(isPresented: Binding(
            get: { auth.showBiometricSetupOffer },
            set: { if !$0 { auth.dismissBiometricSetupOffer(enable: false) } }
        )) {
            BiometricSetupSheet()
        }
    }

    private var bootstrappingView: some View {
        ZStack {
            AuthChromeLayout.screenBackground
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

    private func evaluateOnboarding() {
        showEnterpriseOnboarding = auth.flowState == .signedIn && EnterpriseInstallState.needsEnterpriseSetup
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
        Task {
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
            if auth.selectedWorkspace != nil {
                await chat.loadWorkspaceProjects()
                await chat.loadPlannerTasks()
                if chat.channels.isEmpty, chat.directMessages.isEmpty {
                    await chat.refreshAfterReconnect()
                }
            }
            if let uid = auth.profile?.id {
                await DeviceIdentityService.register(
                    client: auth.client,
                    userId: uid,
                    workspaceId: auth.selectedWorkspace?.id
                )
                await enterprise.loadDevices(client: auth.client, userId: uid)
            }
        }
    }

}
