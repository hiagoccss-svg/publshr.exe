import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    @EnvironmentObject private var spaces: SpacesViewModel
    @EnvironmentObject private var subscription: SubscriptionService
    @EnvironmentObject private var enterprise: EnterpriseWorkspaceService
    @EnvironmentObject private var calls: CallSignalingService

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
        .frame(minWidth: 1280, minHeight: 760)
        .background(Color.clear)
        .preferredColorScheme(.light)
        .onAppear {
            applyAppearance()
            syncEnterpriseData()
            evaluateOnboarding()
        }
        .onChange(of: auth.flowState) { _, _ in
            applyAppearance()
            syncEnterpriseData()
            evaluateOnboarding()
        }
        .onChange(of: auth.selectedMembership?.id) { _, _ in
            syncEnterpriseData()
        }
        .onChange(of: auth.profile?.avatarUrl) { _, _ in
            if let profile = auth.profile {
                chat.upsertProfile(profile)
            }
        }
        .task(id: auth.flowState) {
            guard auth.flowState == .signedIn else { return }
            await runPeriodicSupabaseSync()
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
        .onChange(of: calls.incomingInvite?.id) { oldId, newId in
            guard let newId, oldId != newId else { return }
            calls.bindPresentation(chat: chat, auth: auth)
            calls.presentIncomingRing(chat: chat, auth: auth)
        }
        .onChange(of: calls.activeRoom?.id) { _, roomId in
            guard auth.flowState == .signedIn else { return }
            if roomId != nil {
                CallWindowManager.shared.present(calls: calls, chat: chat, auth: auth)
            } else {
                CallWindowManager.shared.dismiss()
            }
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
            if auth.selectedWorkspace != nil,
               chat.channels.isEmpty, chat.directMessages.isEmpty {
                await chat.refreshAfterReconnect()
            }
            if let uid = auth.profile?.id {
                calls.attach(
                    client: auth.client,
                    userId: uid,
                    displayName: auth.profile?.displayName ?? auth.displayName,
                    workspaceId: auth.selectedWorkspace?.id
                )
                calls.bindPresentation(chat: chat, auth: auth)
                await DeviceIdentityService.register(
                    client: auth.client,
                    userId: uid,
                    workspaceId: auth.selectedWorkspace?.id
                )
                await enterprise.loadDevices(client: auth.client, userId: uid)
            }
        }
    }

    private func runPeriodicSupabaseSync() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            guard auth.flowState == .signedIn else { continue }
            await chat.refreshAfterReconnect()
            await spaces.reload()
            await chat.loadPlannerTasks()
            await subscription.refresh(client: auth.client, workspace: auth.selectedWorkspace)
            if let uid = auth.profile?.id {
                await DeviceIdentityService.register(
                    client: auth.client,
                    userId: uid,
                    workspaceId: auth.selectedWorkspace?.id
                )
            }
        }
    }
}
