import SwiftUI

/// Cursor Mac Light Modern — sign in, sign up, biometrics, email confirmation.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @FocusState private var focusedField: AuthField?

    private enum AuthField: Hashable {
        case name, email, password, code
    }

    var body: some View {
        ZStack {
            CursorTheme.authBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                VStack(spacing: 28) {
                    brandHeader
                    mainCard
                }
                .frame(maxWidth: 440)

                Spacer(minLength: 48)

                footerNote
            }
            .padding(.horizontal, 40)
        }
        .preferredColorScheme(.light)
    }

    private var brandHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(CursorTheme.editorBackground)
                    .frame(width: 56, height: 56)
                    .shadow(color: CursorTheme.authCardShadow, radius: 8, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(CursorTheme.border, lineWidth: 1)
                    )
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
            }
            Text("Publshr")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text(headerSubtitle)
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private var headerSubtitle: String {
        if auth.flowState == .confirmEmail || auth.screen == .confirmEmail {
            return "Verify your email"
        }
        if auth.showBiometricPrompt && auth.screen == .signIn {
            return "Welcome back"
        }
        if auth.screen == .signUp {
            return "Create your account"
        }
        return "Sign in to your workspace"
    }

    @ViewBuilder
    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            if auth.showBiometricPrompt && auth.screen == .signIn {
                biometricSection
                dividerWithLabel("or continue with password")
            }

            if auth.screen != .confirmEmail && auth.flowState != .confirmEmail {
                tabSwitcher
            }

            switch auth.screen {
            case .signIn: signInForm
            case .signUp: signUpForm
            case .confirmEmail: confirmForm
            }

            messageBanners

            if auth.screen == .signIn && auth.canUseBiometrics {
                biometricToggle
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CursorTheme.authCard)
                .shadow(color: CursorTheme.authCardShadow, radius: 16, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
    }

    private var biometricSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await auth.signInWithBiometrics() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "touchid")
                        .font(.system(size: 22))
                    Text("Sign in with \(BiometricAuthService.biometricLabel)")
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(CursorTheme.biometricTint)
                .background(CursorTheme.biometricTint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CursorTheme.biometricTint.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(auth.isLoading)

            if let stored = AuthKeychain.load() {
                Text(stored.email)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }

            Button("Use a different account") { auth.declineBiometrics() }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.accent)
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 2) {
            authTab("Sign in", screen: .signIn)
            authTab("Create account", screen: .signUp)
        }
        .padding(3)
        .background(CursorTheme.sideBar)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func authTab(_ title: String, screen: AuthScreen) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                auth.screen = screen
                auth.errorMessage = nil
                auth.infoMessage = nil
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(auth.screen == screen ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                .background(
                    auth.screen == screen
                        ? CursorTheme.editorBackground
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: auth.screen == screen ? CursorTheme.authCardShadow : .clear, radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            authField("Email", text: $auth.email, field: .email, contentType: .emailAddress)
            authSecureField("Password", text: $auth.password, field: .password)
            primaryButton("Sign in", action: { Task { await auth.signIn() } })
        }
    }

    private var signUpForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            authField("Full name", text: $auth.displayName, field: .name, contentType: .name)
            authField("Work email", text: $auth.email, field: .email, contentType: .emailAddress)
            authSecureField("Password", text: $auth.password, field: .password)
            Text("Use at least 8 characters")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
            primaryButton("Create account", action: { Task { await auth.signUp() } })
        }
    }

    private var confirmForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("We sent a 6-digit code to")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Text(auth.email)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)

            authField("Verification code", text: $auth.otpCode, field: .code, contentType: .oneTimeCode)

            primaryButton("Verify & continue", action: { Task { await auth.confirmEmailOTP() } })

            HStack {
                Button("Resend code") { Task { await auth.resendConfirmation() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
                Spacer()
                Button("Back") {
                    auth.screen = .signIn
                    auth.flowState = .signedOut
                    auth.otpCode = ""
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
    }

    @ViewBuilder
    private var messageBanners: some View {
        if let error = auth.errorMessage {
            banner(error, color: CursorTheme.error, icon: "exclamationmark.circle.fill")
        }
        if let info = auth.infoMessage {
            banner(info, color: CursorTheme.success, icon: "checkmark.circle.fill")
        }
    }

    private func banner(_ text: String, color: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var biometricToggle: some View {
        Toggle(isOn: $auth.enableBiometrics) {
            Text("Use \(BiometricAuthService.biometricLabel) next time")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .toggleStyle(.switch)
    }

    private var footerNote: some View {
        Text("Secured by Supabase · Workspace permissions apply per team")
            .font(.system(size: 11))
            .foregroundStyle(CursorTheme.foregroundDim)
            .padding(.bottom, 16)
    }

    private func dividerWithLabel(_ label: String) -> some View {
        HStack {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private func authField(
        _ label: String,
        text: Binding<String>,
        field: AuthField,
        contentType: NSTextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
            TextField("", text: text, prompt: Text(label).foregroundStyle(CursorTheme.foregroundDim))
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foreground)
                .focused($focusedField, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            focusedField == field ? CursorTheme.inputBorderFocus : CursorTheme.inputBorder,
                            lineWidth: focusedField == field ? 1.5 : 1
                        )
                )
                #if os(macOS)
                .textContentType(contentType)
                #endif
        }
    }

    private func authSecureField(_ label: String, text: Binding<String>, field: AuthField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
            SecureField("", text: text, prompt: Text(label).foregroundStyle(CursorTheme.foregroundDim))
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foreground)
                .focused($focusedField, equals: field)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            focusedField == field ? CursorTheme.inputBorderFocus : CursorTheme.inputBorder,
                            lineWidth: focusedField == field ? 1.5 : 1
                        )
                )
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if auth.isLoading {
                    ProgressView().controlSize(.small).tint(CursorTheme.buttonForeground)
                }
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(CursorTheme.buttonForeground)
            .background(
                auth.isLoading
                    ? CursorTheme.buttonBackground.opacity(0.75)
                    : CursorTheme.buttonBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
    }
}
