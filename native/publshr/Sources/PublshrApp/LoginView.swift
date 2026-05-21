import SwiftUI
import PublshrCore

struct LoginView: View {
    @ObservedObject var supabase = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignUp = false
    @State private var isBusy = false
    @State private var message = ""

    var body: some View {
        ZStack {
            PublshrTheme.bg.ignoresSafeArea()
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Publshr")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(PublshrTheme.textPrimary)
                    Text("Enterprise workspace · Chat · Projects")
                        .foregroundStyle(PublshrTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if isSignUp {
                        TextField("Display name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Use Touch ID to unlock", isOn: Binding(
                        get: { BiometricGate.isEnabled },
                        set: { BiometricGate.isEnabled = $0 }
                    ))
                    .disabled(!BiometricGate.canUseBiometrics)
                }
                .frame(width: 320)

                HStack(spacing: 12) {
                    Button(isSignUp ? "Create account" : "Sign in") {
                        Task { await submit() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PublshrTheme.accent)
                    .disabled(isBusy || email.isEmpty || password.isEmpty)

                    Button(isSignUp ? "Have an account?" : "Sign up") {
                        isSignUp.toggle()
                    }
                    .buttonStyle(.bordered)
                }

                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(width: 320)
                }
            }
            .padding(40)
        }
        .frame(minWidth: 480, minHeight: 520)
    }

    private func submit() async {
        isBusy = true
        message = ""
        defer { isBusy = false }
        do {
            if isSignUp {
                try await supabase.signUp(email: email, password: password, displayName: displayName.isEmpty ? "User" : displayName)
            } else {
                try await supabase.signIn(email: email, password: password)
            }
        } catch {
            message = error.localizedDescription
        }
    }
}

struct BiometricUnlockView: View {
    @State private var failed = false

    var onUnlocked: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "touchid")
                .font(.system(size: 48))
                .foregroundStyle(PublshrTheme.accent)
            Text("Unlock Publshr")
                .font(.title2.bold())
            if failed {
                Text("Try again or disable biometrics in Settings")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            Button("Unlock") {
                Task {
                    if await BiometricGate.authenticate() {
                        onUnlocked()
                    } else {
                        failed = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PublshrTheme.bg)
        .task {
            if await BiometricGate.authenticate() { onUnlocked() }
        }
    }
}
