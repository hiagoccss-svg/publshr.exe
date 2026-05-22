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

    let client: SupabaseClient

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
    }

    var isAuthenticated: Bool { session != nil }

    func bootstrap() async {
        do {
            session = try await client.auth.session
            if session != nil {
                await loadProfile()
            }
        } catch {
            session = nil
        }

        Task {
            for await (_, newSession) in client.auth.authStateChanges {
                session = newSession
                if newSession != nil {
                    await loadProfile()
                } else {
                    profile = nil
                }
            }
        }
    }

    func signIn() async {
        clearMessages()
        guard validateCredentials() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            session = try await client.auth.session
            await loadProfile()
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
            await loadProfile()
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
            password = ""
            otpCode = ""
            screen = .signIn
        } catch {
            errorMessage = friendlyAuthError(error)
        }
    }

    func handleIncomingURL(_ url: URL) {
        Task {
            do {
                try await client.auth.session(from: url)
                session = try await client.auth.session
                await loadProfile()
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
