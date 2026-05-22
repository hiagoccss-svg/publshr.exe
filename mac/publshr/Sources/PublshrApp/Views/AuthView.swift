import SwiftUI

/// Borderless macOS sign-in — no card chrome; session persists via Supabase.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email, password, name, otp
    }

    var body: some View {
        ZStack {
            CursorTheme.activityBar.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 28) {
                    brandHeader

                    if auth.screen != .confirmEmail {
                        modePicker
                    }

                    formContent

                    messages

                    primaryAction
                }
                .frame(maxWidth: 380, alignment: .leading)

                Spacer(minLength: 48)

                footerHint
            }
            .padding(.horizontal, 48)
        }
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
                Text("Publshr")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
            }
            Text(auth.screen == .confirmEmail ? "Confirm your email" : "Enterprise workspace for your team")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 20) {
            modeLink("Sign in", screen: .signIn)
            modeLink("Create account", screen: .signUp)
        }
    }

    private func modeLink(_ title: String, screen: AuthScreen) -> some View {
        Button {
            auth.screen = screen
            auth.errorMessage = nil
            auth.infoMessage = nil
        } label: {
            Text(title)
                .font(.system(size: 13, weight: auth.screen == screen ? .semibold : .regular))
                .foregroundStyle(auth.screen == screen ? CursorTheme.foreground : CursorTheme.foregroundDim)
                .overlay(alignment: .bottom) {
                    if auth.screen == screen {
                        Rectangle()
                            .fill(CursorTheme.accent)
                            .frame(height: 2)
                            .offset(y: 6)
                    }
                }
                .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            switch auth.screen {
            case .signIn:
                if auth.canOfferBiometricUnlock {
                    biometricRow
                }
                authField("Email", text: $auth.email, field: .email, contentType: authEmailContentType)
                authSecureField("Password", text: $auth.password, field: .password)
            case .signUp:
                authField("Name", text: $auth.displayName, field: .name)
                authField("Email", text: $auth.email, field: .email, contentType: authEmailContentType)
                authSecureField("Password", text: $auth.password, field: .password)
                Text("At least 8 characters")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
            case .confirmEmail:
                Text("Enter the 6-digit code sent to \(auth.email)")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .fixedSize(horizontal: false, vertical: true)
                authField("Code", text: $auth.otpCode, field: .otp, contentType: authOTPContentType)
                HStack(spacing: 16) {
                    Button("Resend code") { Task { await auth.resendConfirmation() } }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.accent)
                    Button("Back to sign in") {
                        auth.screen = .signIn
                        auth.otpCode = ""
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundDim)
                }
            }
        }
    }

    private var biometricRow: some View {
        Button {
            Task { await auth.unlockWithBiometrics() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "touchid")
                    .font(.system(size: 15))
                Text("Unlock with \(BiometricAuthService.biometricLabel)")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(CursorTheme.accent)
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
    }

    @ViewBuilder
    private var messages: some View {
        if let error = auth.errorMessage {
            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let info = auth.infoMessage {
            Text(info)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.success)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var primaryAction: some View {
        Button {
            Task {
                switch auth.screen {
                case .signIn: await auth.signIn()
                case .signUp: await auth.signUp()
                case .confirmEmail: await auth.confirmEmailOTP()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if auth.isLoading {
                    ProgressView().controlSize(.small)
                }
                Text(primaryTitle)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .foregroundStyle(CursorTheme.accent)
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
        .keyboardShortcut(.return, modifiers: .command)
    }

    private var primaryTitle: String {
        switch auth.screen {
        case .signIn: return "Sign in"
        case .signUp: return "Create account"
        case .confirmEmail: return "Verify email"
        }
    }

    private var footerHint: some View {
        Text("Signed-in sessions stay active on this Mac. Enable Touch ID in Settings for optional quick unlock.")
            .font(.system(size: 11))
            .foregroundStyle(CursorTheme.foregroundDim)
            .frame(maxWidth: 380, alignment: .leading)
    }

    private var authEmailContentType: NSTextContentType? {
        if #available(macOS 14.0, *) { return .emailAddress }
        return .username
    }

    private var authOTPContentType: NSTextContentType? {
        if #available(macOS 14.0, *) { return .oneTimeCode }
        return nil
    }

    private func authField(
        _ label: String,
        text: Binding<String>,
        field: Field,
        contentType: NSTextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(CursorTheme.foreground)
                .focused($focusedField, equals: field)
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(focusedField == field ? CursorTheme.accent : CursorTheme.border.opacity(0.6))
                        .frame(height: 1)
                }
                #if os(macOS)
                .textContentType(contentType)
                #endif
        }
    }

    private func authSecureField(_ label: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
            SecureField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundStyle(CursorTheme.foreground)
                .focused($focusedField, equals: field)
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(focusedField == field ? CursorTheme.accent : CursorTheme.border.opacity(0.6))
                        .frame(height: 1)
                }
        }
    }
}
