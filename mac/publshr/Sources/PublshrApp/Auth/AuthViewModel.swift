import Foundation
import Supabase
import SwiftUI

enum AuthScreen: Equatable {
    case signIn
    case signUp
    case confirmEmail
}

enum SessionUnlockMethod: String {
    case persisted
    case biometric
    case password
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
    /// Bumps when avatar storage path changes so `ChatProfileAvatar` reloads signed URLs.
    @Published private(set) var avatarDisplayToken = UUID()

    @Published var flowState: AuthFlowState = .bootstrapping
    @Published var workspaceMemberships: [WorkspaceMembership] = []
    @Published var selectedMembership: WorkspaceMembership?
    @Published var newWorkspaceName = ""
    @Published var isCreatingWorkspace = false
    @Published var supabaseStatusLine = "Connecting…"
    @Published var isRefreshingConnection = false
    /// False when signed in from cache / expired JWT until Supabase refresh succeeds.
    @Published private(set) var isCloudValidated = true

    /// Optional quick unlock — never required to use the app.
    @AppStorage("publshr.useBiometricUnlock") var biometricUnlockEnabled = false
    @AppStorage("publshr.didOfferBiometricSetup") private var didOfferBiometricSetup = false
    @Published var showBiometricSetupOffer = false

    let client: SupabaseClient
    private static let lastWorkspaceKey = "com.publshr.app.lastWorkspaceId"
    private static let lastEmailKey = "com.publshr.app.lastEmail"

    var selectedWorkspace: Workspace? { selectedMembership?.workspace }

    var workspaceChatPermissions: ChatWorkspacePermissions {
        selectedMembership?.chatPermissions() ?? .default
    }

    var prefersBiometricUnlock: Bool {
        biometricUnlockEnabled && BiometricAuthService.isAvailable && AuthKeychain.load() != nil
    }

    var canOfferBiometricUnlock: Bool {
        biometricUnlockEnabled && BiometricAuthService.isAvailable && AuthKeychain.load() != nil
    }

    init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: SupabaseConfig.authRedirect,
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        if let saved = UserDefaults.standard.string(forKey: Self.lastEmailKey), !saved.isEmpty {
            email = saved
        }
        Task { await bootstrap() }

        Task {
            for await (event, newSession) in client.auth.authStateChanges {
                switch event {
                case .signedOut:
                    session = nil
                    profile = nil
                    workspaceMemberships = []
                    selectedMembership = nil
                    flowState = .signedOut
                    supabaseStatusLine = "Signed out"
                case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                    session = newSession
                    if newSession != nil {
                        await loadProfile()
                        await loadWorkspaces()
                        restoreLastWorkspaceSelection()
                        updateSupabaseStatus(connected: true)
                    }
                    resolveFlowStateAfterSession()
                default:
                    if let newSession {
                        session = newSession
                        resolveFlowStateAfterSession()
                    }
                }
            }
        }
    }

    var isAuthenticated: Bool { session != nil && flowState == .signedIn }

    private var isNetworkReachable: Bool {
        AppLifecycleService.shared.isNetworkReachable
    }

    func bootstrap() async {
        await completeBootstrap()
    }

    func completeBootstrap() async {
        flowState = .bootstrapping
        isCloudValidated = false
        updateSupabaseStatus(connected: false)

        // 1) Restore persisted Supabase session (online refresh when needed).
        if let existing = await loadPersistedSession() {
            session = existing
            if await gateSessionWithBiometricIfNeeded() {
                await finishSessionRestore(
                    reconcileCloud: isNetworkReachable,
                    unlockMethod: .persisted
                )
            }
            return
        }

        // 2) Keychain + biometrics — works offline (cached permissions) and online (Supabase reconcile).
        if canAttemptKeychainUnlock, let restored = await restoreSessionFromKeychain(requireBiometric: prefersBiometricUnlock) {
            session = restored
            await finishSessionRestore(
                reconcileCloud: isNetworkReachable,
                unlockMethod: prefersBiometricUnlock ? .biometric : .persisted
            )
            return
        }

        flowState = .signedOut
        isCloudValidated = false
        supabaseStatusLine = "Not signed in"
    }

    private var canAttemptKeychainUnlock: Bool {
        AuthKeychain.load() != nil || AuthOfflineSessionCache.load() != nil
    }

    private func loadPersistedSession() async -> Session? {
        do {
            let current = try await client.auth.session
            if isNetworkReachable {
                if current.isExpired {
                    let refreshed = try await client.auth.refreshSession()
                    updateSupabaseStatus(connected: true)
                    return refreshed
                }
                updateSupabaseStatus(connected: true)
                return current
            }
            if AuthJWT.isAccessTokenExpired(current.accessToken) {
                return nil
            }
            return current
        } catch {
            return nil
        }
    }

    func transitionAfterSignIn() async {
        if let mail = session?.user.email ?? email.nonEmptyOrNil {
            UserDefaults.standard.set(mail, forKey: Self.lastEmailKey)
            email = mail
        }
        if biometricUnlockEnabled {
            persistSessionToKeychain()
        } else if BiometricAuthService.isAvailable, !didOfferBiometricSetup {
            showBiometricSetupOffer = true
        }
        await finishSessionRestore(reconcileCloud: true, unlockMethod: .password)
    }

    private func finishSessionRestore(reconcileCloud: Bool, unlockMethod: SessionUnlockMethod) async {
        if reconcileCloud, isNetworkReachable {
            await reconcileCloudSession(unlockMethod: unlockMethod)
        } else {
            applyOfflineSnapshotIfAvailable()
            isCloudValidated = false
            supabaseStatusLine = isNetworkReachable
                ? "Reconnecting to Supabase…"
                : "Offline — cached workspace and permissions"
        }
        resolveFlowStateAfterSession()
    }

    /// Refresh JWT, reload workspaces/permissions from Supabase, register device, and refresh offline cache.
    func reconcileCloudSession(unlockMethod: SessionUnlockMethod?) async {
        guard isNetworkReachable, session != nil else { return }
        isRefreshingConnection = true
        defer { isRefreshingConnection = false }

        do {
            if let current = try? await client.auth.session, current.isExpired {
                session = try await client.auth.refreshSession()
            } else if session == nil, let stored = AuthKeychain.load() {
                try await client.auth.setSession(
                    accessToken: stored.accessToken,
                    refreshToken: stored.refreshToken
                )
                session = try await client.auth.session
            }
            if let active = session, active.isExpired {
                session = try await client.auth.refreshSession()
            }
            session = try await client.auth.session
            await loadProfile()
            await loadWorkspaces()
            restoreLastWorkspaceSelection()
            persistOfflineSnapshot()
            isCloudValidated = true
            updateSupabaseStatus(connected: true)
            persistSessionToKeychain()
            if let method = unlockMethod, let uid = session?.user.id {
                await DeviceIdentityService.recordSessionUnlock(
                    client: client,
                    userId: uid,
                    workspaceId: selectedWorkspace?.id,
                    method: method.rawValue
                )
            }
            errorMessage = nil
        } catch {
            if applyOfflineSnapshotIfAvailable() {
                isCloudValidated = false
                supabaseStatusLine = "Offline — cached workspace until Supabase reconnects"
            } else {
                errorMessage = friendlyAuthError(error)
                supabaseStatusLine = "Connection error"
            }
        }
    }

    @discardableResult
    private func applyOfflineSnapshotIfAvailable() -> Bool {
        guard let snap = AuthOfflineSessionCache.load() else { return false }
        profile = snap.profile
        workspaceMemberships = AuthOfflineSessionCache.memberships(from: snap)
        if let selectedId = snap.selectedWorkspaceId,
           let match = workspaceMemberships.first(where: { $0.workspace.id == selectedId }) {
            selectedMembership = match
        } else {
            restoreLastWorkspaceSelection()
        }
        if session == nil, let stored = AuthKeychain.load() {
            Task {
                try? await client.auth.setSession(
                    accessToken: stored.accessToken,
                    refreshToken: stored.refreshToken
                )
            }
        }
        return true
    }

    private func persistOfflineSnapshot() {
        AuthOfflineSessionCache.save(
            profile: profile,
            memberships: workspaceMemberships,
            selectedWorkspaceId: selectedMembership?.workspace.id
        )
        if let session {
            let stored = AuthKeychain.StoredSession(
                email: session.user.email ?? email,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id
            )
            if biometricUnlockEnabled {
                _ = AuthKeychain.save(stored)
            }
        }
    }

    /// When Touch ID is enabled, require a successful scan before showing the IDE.
    private func gateSessionWithBiometricIfNeeded() async -> Bool {
        guard prefersBiometricUnlock else { return true }
        let ok = await BiometricAuthService.authenticate(reason: "Unlock Publshr")
        if ok { return true }
        session = nil
        flowState = .signedOut
        infoMessage = "Quick unlock was cancelled. Sign in with your password."
        return false
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

            var workspaces = try await service.fetchMemberWorkspaces(userId: userId)
            if workspaces.isEmpty {
                workspaces = try await service.fetchWorkspaces()
            }
            if workspaces.isEmpty {
                let label = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
                let fallback = (label?.isEmpty == false) ? label! : "My"
                let created = try await service.createWorkspace(name: "\(fallback) Workspace")
                workspaces = [created]
            }

            let memberRows: [WorkspaceMember] = try await client
                .from("workspace_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            let roleByWorkspace = Dictionary(uniqueKeysWithValues: memberRows.map { ($0.workspaceId, $0.role) })
            workspaceMemberships = workspaces.map { ws in
                let roleRaw = roleByWorkspace[ws.id] ?? (ws.ownerId == userId ? WorkspaceRole.owner.rawValue : WorkspaceRole.member.rawValue)
                let role = WorkspaceRole(rawValue: roleRaw) ?? .member
                return WorkspaceMembership(workspace: ws, role: role)
            }.sorted { $0.workspace.name.localizedCaseInsensitiveCompare($1.workspace.name) == .orderedAscending }

            if workspaceMemberships.count == 1 {
                selectedMembership = workspaceMemberships.first
                saveLastWorkspaceSelection()
            }
            persistOfflineSnapshot()
            resolveFlowStateAfterSession()
        } catch {
            errorMessage = friendlyWorkspaceError(error)
            if !applyOfflineSnapshotIfAvailable() {
                workspaceMemberships = []
            }
            isCloudValidated = false
            supabaseStatusLine = "Workspace sync failed"
        }
    }

    private func friendlyWorkspaceError(_ error: Error) -> String {
        let text = String(describing: error)
        if text.localizedCaseInsensitiveContains("create_workspace")
            || text.localizedCaseInsensitiveContains("function")
            || text.localizedCaseInsensitiveContains("does not exist") {
            return "Workspace setup is not ready on the server. Ask your admin to apply Supabase migration 20260522000000_enterprise_foundation.sql."
        }
        if text.localizedCaseInsensitiveContains("row-level security")
            || text.localizedCaseInsensitiveContains("permission denied") {
            return "You do not have permission to access workspaces. Contact your administrator."
        }
        return error.localizedDescription
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
            errorMessage = friendlyWorkspaceError(error)
        }
    }

    func switchWorkspace(_ membership: WorkspaceMembership) {
        selectedMembership = membership
        saveLastWorkspaceSelection()
    }

    func unlockWithBiometrics() async -> Bool {
        guard canOfferBiometricUnlock || AuthKeychain.load() != nil else { return false }
        guard let restored = await restoreSessionFromKeychain(requireBiometric: true) else { return false }
        session = restored
        await finishSessionRestore(
            reconcileCloud: isNetworkReachable,
            unlockMethod: .biometric
        )
        return flowState == .signedIn || flowState == .selectWorkspace
    }

    func setBiometricUnlockEnabled(_ enabled: Bool) {
        if !enabled {
            biometricUnlockEnabled = false
            AuthKeychain.delete()
            return
        }
        Task { await enableBiometricUnlock() }
    }

    /// Verify with Touch ID / password, then store session for quick unlock.
    func enableBiometricUnlock() async {
        guard BiometricAuthService.isAvailable else {
            errorMessage = "\(BiometricAuthService.biometricLabel) is not available on this Mac."
            return
        }
        guard session != nil else {
            errorMessage = "Sign in first, then enable quick unlock in Settings."
            return
        }
        let ok = await BiometricAuthService.authenticate(
            reason: "Enable \(BiometricAuthService.biometricLabel) for Publshr"
        )
        guard ok else { return }
        biometricUnlockEnabled = true
        didOfferBiometricSetup = true
        persistSessionToKeychain()
        infoMessage = "\(BiometricAuthService.biometricLabel) is enabled for this Mac."
    }

    func dismissBiometricSetupOffer(enable: Bool) {
        showBiometricSetupOffer = false
        didOfferBiometricSetup = true
        if enable {
            Task { await enableBiometricUnlock() }
        }
    }

    func persistSessionToKeychain() {
        guard biometricUnlockEnabled, let session else { return }
        guard BiometricAuthService.isAvailable else { return }
        let stored = AuthKeychain.StoredSession(
            email: session.user.email ?? email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id
        )
        _ = AuthKeychain.save(stored)
        persistOfflineSnapshot()
    }

    private func restoreSessionFromKeychain(requireBiometric: Bool) async -> Session? {
        if requireBiometric {
            let ok = await BiometricAuthService.authenticate(reason: "Unlock Publshr")
            guard ok else { return nil }
        }

        _ = applyOfflineSnapshotIfAvailable()

        guard let stored = AuthKeychain.load() else {
            return try? await client.auth.session
        }

        try? await client.auth.setSession(
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken
        )

        if isNetworkReachable {
            do {
                var current = try await client.auth.session
                if current.isExpired {
                    current = try await client.auth.refreshSession()
                }
                updateSupabaseStatus(connected: true)
                return current
            } catch {
                return try? await client.auth.session
            }
        }

        return try? await client.auth.session
    }

    func refreshSupabaseConnection() async {
        await reconcileCloudSession(unlockMethod: nil)
        resolveFlowStateAfterSession()
    }

    private func updateSupabaseStatus(connected: Bool) {
        if connected, session != nil {
            let host = SupabaseConfig.displayHost
            supabaseStatusLine = "Connected · \(host)"
        } else {
            supabaseStatusLine = "Not connected"
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
            password = ""
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
            isCloudValidated = false
            AuthOfflineSessionCache.clear()
            if !biometricUnlockEnabled {
                AuthKeychain.delete()
            }
            supabaseStatusLine = "Signed out"
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
        guard let userId = session?.user.id else { return }
        do {
            let rows: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            profile = rows.first
        } catch {
            profile = nil
        }
    }

    func uploadAvatar(data: Data, mimeType: String) async throws {
        guard let userId = session?.user.id else {
            throw ChatServiceError.notAuthenticated
        }
        let updated = try await ProfileService.uploadAvatar(
            client: client,
            userId: userId,
            data: data,
            mimeType: mimeType
        )
        profile = updated
        avatarDisplayToken = UUID()
    }

    func updateDisplayName(_ name: String) async throws {
        guard let userId = session?.user.id else {
            throw ChatServiceError.notAuthenticated
        }
        let updated = try await ProfileService.updateDisplayName(
            client: client,
            userId: userId,
            displayName: name
        )
        profile = updated
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

private extension String {
    var nonEmptyOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
