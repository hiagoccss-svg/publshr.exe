import Foundation
import Supabase

enum AuthScreen: Equatable {
    case signIn
    case signUp
    case confirmEmail
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var screen: AuthScreen = .signIn
    @Published var email = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var otpCode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var session: Session?
    @Published var profile: Profile?

    @Published var flowState: AuthFlowState = .bootstrapping
    @Published var workspaceMemberships: [WorkspaceMembership] = []
    @Published var selectedMembership: WorkspaceMembership?
    @Published var newWorkspaceName = ""
    @Published var isCreatingWorkspace = false
    @Published var biometricUnlockRequired = false
    @Published var prefersBiometricUnlock = false

    let client: SupabaseClient
    private static let lastWorkspaceKey = "com.publshr.app.lastWorkspaceId"

    var selectedWorkspace: Workspace? { selectedMembership?.workspace }

    var workspaceChatPermissions: ChatWorkspacePermissions {
        selectedMembership?.chatPermissions() ?? .default
    }

    init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: SupabaseConfig.authRedirect,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        Task { await bootstrap() }

        Task {
            for await (_, newSession) in client.auth.authStateChanges {
                session = newSession
                if newSession != nil {
                    await loadProfile()
                    await loadWorkspaces()
                    restoreLastWorkspaceSelection()
                } else {
                    profile = nil
                    workspaceMemberships = []
                    selectedMembership = nil
                    flowState = .signedOut
                }
                resolveFlowStateAfterSession()
            }
        }
    }

    var isAuthenticated: Bool { session != nil && flowState == .signedIn }

    func bootstrap() async {
        await completeBootstrap()
    }

    func completeBootstrap() async {
        flowState = .bootstrapping
        prefersBiometricUnlock = BiometricAuthService.isAvailable && AuthKeychain.load() != nil

        if prefersBiometricUnlock {
            biometricUnlockRequired = true
            let ok = await BiometricAuthService.authenticate(reason: "Unlock Publshr")
            biometricUnlockRequired = false
            if !ok {
                session = nil
                try? await client.auth.signOut()
                flowState = .signedOut
                return
            }
            if let restored = await restoreSessionFromKeychain() {
                session = restored
            }
        }

        if session == nil {
            do {
                session = try await client.auth.session
            } catch {
                session = nil
            }
        }

        if session != nil {
            await loadProfile()
            await loadWorkspaces()
            restoreLastWorkspaceSelection()
        }
        resolveFlowStateAfterSession()
    }

    func transitionAfterSignIn() async {
        persistSessionToKeychain()
        await loadProfile()
        await loadWorkspaces()
        restoreLastWorkspaceSelection()
        resolveFlowStateAfterSession()
    }

    func resolveFlowStateAfterSession() {
        if session == nil {
            flowState = screen == .confirmEmail ? .confirmEmail : .signedOut
            return
        }
        if screen == .confirmEmail {
            flowState = .confirmEmail
            return
        }
        if selectedMembership == nil {
            flowState = .selectWorkspace
            return
        }
        flowState = .signedIn
    }

    func loadWorkspaces() async {
        guard let userId = profile?.id ?? session?.user.id else {
            workspaceMemberships = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let service = ChatService(client: client)
            let members: [WorkspaceMember] = try await client
                .from("workspace_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            var workspaces = try await service.fetchMemberWorkspaces(userId: userId)
            if workspaces.isEmpty {
                workspaces = try await service.fetchWorkspaces()
            }

            let roleByWorkspace = Dictionary(uniqueKeysWithValues: members.map { ($0.workspaceId, $0.role) })
            workspaceMemberships = workspaces.map { ws in
                let roleRaw = roleByWorkspace[ws.id] ?? (ws.ownerId == userId ? WorkspaceRole.owner.rawValue : WorkspaceRole.member.rawValue)
                let role = WorkspaceRole(rawValue: roleRaw) ?? .member
                return WorkspaceMembership(workspace: ws, role: role)
            }.sorted { $0.workspace.name.localizedCaseInsensitiveCompare($1.workspace.name) == .orderedAscending }

            if workspaceMemberships.count == 1 {
                selectedMembership = workspaceMemberships.first
                saveLastWorkspaceSelection()
            }
            resolveFlowStateAfterSession()
        } catch {
            errorMessage = error.localizedDescription
            workspaceMemberships = []
        }
    }

    func confirmWorkspaceSelection() async {
        guard selectedMembership != nil else {
            errorMessage = "Select a workspace to continue."
            return
        }
        saveLastWorkspaceSelection()
        flowState = .signedIn
        errorMessage = nil
    }

    func createWorkspaceAndContinue() async {
        let name = newWorkspaceName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            errorMessage = "Enter a workspace name."
            return
        }
        isCreatingWorkspace = true
        defer { isCreatingWorkspace = false }
        do {
            let service = ChatService(client: client)
            let ws = try await service.createWorkspace(name: name)
            let membership = WorkspaceMembership(workspace: ws, role: .owner)
            workspaceMemberships.append(membership)
            selectedMembership = membership
            newWorkspaceName = ""
            saveLastWorkspaceSelection()
            flowState = .signedIn
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchWorkspace(_ membership: WorkspaceMembership) {
        selectedMembership = membership
        saveLastWorkspaceSelection()
    }

    func unlockWithBiometrics() async -> Bool {
        guard BiometricAuthService.isAvailable else { return false }
        let ok = await BiometricAuthService.authenticate(reason: "Unlock Publshr")
        if ok { await completeBootstrap() }
        return ok
    }

    func persistSessionToKeychain() {
        guard let session else { return }
        guard BiometricAuthService.isAvailable else { return }
        let stored = AuthKeychain.StoredSession(
            email: session.user.email ?? email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
        _ = AuthKeychain.save(stored)
        prefersBiometricUnlock = true
    }

    /// Restores Supabase session from Keychain tokens after biometric unlock (no localStorage).
    private func restoreSessionFromKeychain() async -> Session? {
        guard let stored = AuthKeychain.load() else { return nil }
        do {
            try await client.auth.setSession(accessToken: stored.accessToken, refreshToken: stored.refreshToken)
            let current = try await client.auth.session
            persistSessionToKeychain()
            return current
        } catch {
            return nil
        }
    }

    private func saveLastWorkspaceSelection() {
        guard let id = selectedMembership?.workspace.id else { return }
        UserDefaults.standard.set(id.uuidString, forKey: Self.lastWorkspaceKey)
    }

    private func restoreLastWorkspaceSelection() {
        guard let raw = UserDefaults.standard.string(forKey: Self.lastWorkspaceKey),
              let id = UUID(uuidString: raw),
              let match = workspaceMemberships.first(where: { $0.workspace.id == id }) else { return }
        selectedMembership = match
    }

    func signIn() async {
        clearMessages()
        guard validateCredentials() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            session = try await client.auth.session
            await transitionAfterSignIn()
            errorMessage = nil
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func signUp() async {
        clearMessages()
        guard validateCredentials(requireName: true) else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let name = displayName.trimmingCharacters(in: .whitespaces)
            _ = try await client.auth.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                data: [
                    "display_name": .string(name.isEmpty ? emailPrefix : name),
                ],
                redirectTo: SupabaseConfig.authRedirect
            )
            infoMessage = "Check your email for a 6-digit confirmation code."
            screen = .confirmEmail
            errorMessage = nil
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func confirmEmailOTP() async {
        clearMessages()
        let code = otpCode.trimmingCharacters(in: .whitespaces)
        guard code.count >= 6 else {
            errorMessage = "Enter the 6-digit code from your email."
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.verifyOTP(
                email: email.trimmingCharacters(in: .whitespaces),
                token: code,
                type: .signup
            )
            session = try await client.auth.session
            await transitionAfterSignIn()
            infoMessage = nil
            errorMessage = nil
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func resendConfirmation() async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.resend(email: email.trimmingCharacters(in: .whitespaces), type: .signup)
            infoMessage = "Confirmation email sent again."
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            session = nil
            profile = nil
            workspaceMemberships = []
            selectedMembership = nil
            password = ""
            otpCode = ""
            screen = .signIn
            flowState = .signedOut
            AuthKeychain.delete()
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func handleIncomingURL(_ url: URL) {
        Task {
            do {
                try await client.auth.session(from: url)
                session = try await client.auth.session
                await transitionAfterSignIn()
            } catch {
                errorMessage = friendlyAuthError(error)
            }
        }
    }

    func loadProfile() async {
        guard session != nil else { return }
        do {
            let rows: [Profile] = try await client
                .from("profiles")
                .select()
                .limit(1)
                .execute()
                .value
            profile = rows.first
        } catch {
            profile = nil
        }
    }

    private var emailPrefix: String {
        email.split(separator: "@").first.map(String.init) ?? "User"
    }

    private func validateCredentials(requireName: Bool = false) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty || !trimmedEmail.contains("@") {
            errorMessage = "Enter a valid email address."
            return false
        }
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        if requireName && displayName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Enter your name to create an account."
            return false
        }
        return true
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func friendlyAuthError(_ error: Error) -> String {
        let text = String(describing: error)
        if text.localizedCaseInsensitiveContains("email not confirmed") {
            screen = .confirmEmail
            return "Confirm your email with the 6-digit code we sent you."
        }
        if text.localizedCaseInsensitiveContains("invalid") && text.localizedCaseInsensitiveContains("email") {
            return "That email address is not allowed. Use a real email you can access."
        }
        if text.localizedCaseInsensitiveContains("invalid login") || text.localizedCaseInsensitiveContains("invalid credentials") {
            return "Incorrect email or password."
        }
        if text.localizedCaseInsensitiveContains("already registered") || text.localizedCaseInsensitiveContains("already exists") {
            return "An account with this email already exists. Sign in instead."
        }
        return error.localizedDescription
    }
}
