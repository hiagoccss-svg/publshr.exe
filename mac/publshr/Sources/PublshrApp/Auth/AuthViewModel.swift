import Foundation
import Supabase

enum AuthScreen: Equatable {
    case signIn
    case signUp
    case confirmEmail
}

enum AuthFlowState: Equatable {
    case bootstrapping
    case signedOut
    case confirmEmail
    case selectWorkspace
    case signedIn
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var flowState: AuthFlowState = .bootstrapping
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

    @Published var enableBiometrics = true
    @Published var canUseBiometrics = false
    @Published var showBiometricPrompt = false

    @Published var workspaceMemberships: [WorkspaceMembership] = []
    @Published var selectedMembership: WorkspaceMembership?
    @Published var newWorkspaceName = ""
    @Published var isCreatingWorkspace = false

    let client: SupabaseClient

    var isAuthenticated: Bool { session != nil && flowState == .signedIn }
    var currentUserId: UUID? { session?.user.id }
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
        canUseBiometrics = BiometricAuthService.isAvailable
        Task { await bootstrap() }
    }

    // MARK: - Bootstrap

    func bootstrap() async {
        flowState = .bootstrapping
        canUseBiometrics = BiometricAuthService.isAvailable
        listenForAuthChanges()

        await restoreExistingSession()
        if flowState == .signedIn { return }

        if let stored = AuthKeychain.load(), canUseBiometrics {
            email = stored.email
            showBiometricPrompt = true
        }
        flowState = flowState == .bootstrapping ? .signedOut : flowState
    }

    private func listenForAuthChanges() {
        Task {
            for await (_, newSession) in client.auth.authStateChanges {
                session = newSession
                if newSession != nil {
                    await onSessionEstablished()
                } else {
                    profile = nil
                    selectedMembership = nil
                    workspaceMemberships = []
                    flowState = .signedOut
                }
            }
        }
    }

    private func restoreExistingSession() async {
        do {
            session = try await client.auth.session
            if session != nil {
                await onSessionEstablished()
                return
            }
        } catch {
            session = nil
        }
        flowState = .signedOut
    }

    func signInWithBiometrics() async {
        clearMessages()
        guard canUseBiometrics, let stored = AuthKeychain.load() else {
            errorMessage = "\(BiometricAuthService.biometricLabel) is not available."
            return
        }
        guard await BiometricAuthService.authenticate(reason: "Sign in to Publshr") else {
            errorMessage = "\(BiometricAuthService.biometricLabel) was cancelled."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await client.auth.setSession(
                accessToken: stored.accessToken,
                refreshToken: stored.refreshToken
            )
            session = try await client.auth.session
            email = stored.email
            await onSessionEstablished()
        } catch {
            AuthKeychain.delete()
            errorMessage = "Session expired. Sign in with your password."
            showBiometricPrompt = false
        }
    }

    func declineBiometrics() {
        showBiometricPrompt = false
        AuthKeychain.delete()
    }

    // MARK: - Sign in / up

    func signIn() async {
        clearMessages()
        guard validateCredentials() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            session = try await client.auth.signIn(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            await persistSessionIfNeeded()
            await onSessionEstablished()
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
            let response = try await client.auth.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                redirectTo: SupabaseConfig.authRedirect,
                data: ["display_name": .string(name.isEmpty ? emailPrefix : name)]
            )
            if let s = response.session {
                session = s
                await persistSessionIfNeeded()
                await onSessionEstablished()
                infoMessage = "Account created successfully."
                return
            }
            infoMessage = "Check your email for a 6-digit confirmation code."
            screen = .confirmEmail
            flowState = .confirmEmail
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
            await persistSessionIfNeeded()
            await onSessionEstablished()
            infoMessage = nil
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
        } catch { /* ignore */ }
        AuthKeychain.delete()
        session = nil
        profile = nil
        selectedMembership = nil
        workspaceMemberships = []
        password = ""
        otpCode = ""
        screen = .signIn
        flowState = .signedOut
        showBiometricPrompt = AuthKeychain.load() != nil && canUseBiometrics
    }

    func handleIncomingURL(_ url: URL) {
        Task {
            do {
                try await client.auth.session(from: url)
                session = try await client.auth.session
                await persistSessionIfNeeded()
                await onSessionEstablished()
            } catch {
                errorMessage = friendlyAuthError(error)
            }
        }
    }

    // MARK: - Workspace

    func loadWorkspaces() async {
        guard let userId = currentUserId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let members: [WorkspaceMember] = try await client
                .from("workspace_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            guard !members.isEmpty else {
                workspaceMemberships = []
                return
            }
            let ids = members.map(\.workspaceId.uuidString)
            let workspaces: [Workspace] = try await client
                .from("workspaces")
                .select()
                .in("id", values: ids)
                .execute()
                .value
            let roleMap = Dictionary(uniqueKeysWithValues: members.map { ($0.workspaceId, WorkspaceRole(rawValue: $0.role) ?? .member) })
            workspaceMemberships = workspaces.map { ws in
                WorkspaceMembership(workspace: ws, role: roleMap[ws.id] ?? .member)
            }.sorted { $0.workspace.name < $1.workspace.name }

            if let savedId = UserDefaults.standard.string(forKey: lastWorkspaceKey),
               let uuid = UUID(uuidString: savedId),
               let match = workspaceMemberships.first(where: { $0.id == uuid }) {
                selectedMembership = match
            }
        } catch {
            errorMessage = "Could not load workspaces: \(error.localizedDescription)"
        }
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
            struct Params: Encodable { let p_name: String }
            let ws: Workspace = try await client
                .rpc("create_workspace", params: Params(p_name: name))
                .execute()
                .value
            let membership = WorkspaceMembership(workspace: ws, role: .owner)
            workspaceMemberships.insert(membership, at: 0)
            selectedMembership = membership
            newWorkspaceName = ""
            await confirmWorkspaceSelection()
        } catch {
            errorMessage = "Could not create workspace: \(error.localizedDescription)"
        }
    }

    func confirmWorkspaceSelection() async {
        guard let membership = selectedMembership else {
            errorMessage = "Select a workspace to continue."
            return
        }
        UserDefaults.standard.set(membership.id.uuidString, forKey: lastWorkspaceKey)
        flowState = .signedIn
        errorMessage = nil
    }

    func switchWorkspace(_ membership: WorkspaceMembership) {
        selectedMembership = membership
        UserDefaults.standard.set(membership.id.uuidString, forKey: lastWorkspaceKey)
    }

    // MARK: - Session helpers

    private func onSessionEstablished() async {
        await loadProfile()
        await loadWorkspaces()
        if workspaceMemberships.isEmpty {
            flowState = .selectWorkspace
        } else if selectedMembership != nil {
            flowState = .signedIn
        } else if workspaceMemberships.count == 1 {
            selectedMembership = workspaceMemberships[0]
            UserDefaults.standard.set(workspaceMemberships[0].id.uuidString, forKey: lastWorkspaceKey)
            flowState = .signedIn
        } else {
            flowState = .selectWorkspace
        }
        showBiometricPrompt = false
    }

    private func persistSessionIfNeeded() async {
        guard enableBiometrics, canUseBiometrics,
              let session, let refresh = session.refreshToken else { return }
        let stored = AuthKeychain.StoredSession(
            email: email.trimmingCharacters(in: .whitespaces).isEmpty
                ? (session.user.email ?? "")
                : email.trimmingCharacters(in: .whitespaces),
            accessToken: session.accessToken,
            refreshToken: refresh,
            userId: session.user.id
        )
        _ = AuthKeychain.save(stored)
    }

    func loadProfile() async {
        guard let userId = currentUserId else { return }
        do {
            let rows: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            if let row = rows.first {
                profile = row
                return
            }
            await ensureProfileRow(userId: userId)
        } catch {
            await ensureProfileRow(userId: userId)
        }
    }

    private func ensureProfileRow(userId: UUID) async {
        let userEmail = session?.user.email ?? email
        let metaName: String? = {
            guard let meta = session?.user.userMetadata["display_name"] else { return nil }
            if case .string(let s) = meta { return s }
            return nil
        }()
        let name = displayName.isEmpty ? (metaName ?? emailPrefix) : displayName
        do {
            let row: Profile = try await client
                .from("profiles")
                .upsert(ProfileUpsert(id: userId, email: userEmail, display_name: name))
                .select()
                .single()
                .execute()
                .value
            profile = row
        } catch {
            profile = Profile(id: userId, email: userEmail, displayName: name, avatarUrl: nil)
        }
    }

    private var lastWorkspaceKey: String { "publshr.last_workspace_id" }

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
            flowState = .confirmEmail
            return "Confirm your email with the 6-digit code we sent you."
        }
        if text.localizedCaseInsensitiveContains("invalid login") || text.localizedCaseInsensitiveContains("invalid credentials") {
            return "Incorrect email or password."
        }
        if text.localizedCaseInsensitiveContains("already registered") || text.localizedCaseInsensitiveContains("already exists") {
            return "An account with this email already exists. Sign in instead."
        }
        if text.localizedCaseInsensitiveContains("rate limit") {
            return "Too many attempts. Wait a moment and try again."
        }
        return error.localizedDescription
    }
}

private struct ProfileUpsert: Encodable {
    let id: UUID
    let email: String
    let display_name: String
}
