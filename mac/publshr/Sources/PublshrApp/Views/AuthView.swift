import SwiftUI

/// macOS-native sign-in — light auth surface, card layout, readable contrast.
struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email, password, name, otp
    }

    var body: some View {
        ZStack {
            AuthChromeLayout.screenBackground

            VStack(spacing: 0) {
                Color.clear.frame(height: AuthChromeLayout.topChromeInset)
                Spacer(minLength: 24)

                AuthChromeLayout.card {
                    brandHeader
                    if auth.screen != .confirmEmail { modePicker }
                    formContent
                    messages
                    primaryAction
                }

                Spacer(minLength: 24)
                footerHint
                    .padding(.horizontal, AuthChromeLayout.horizontalPadding)
                    .frame(maxWidth: AuthChromeLayout.cardMaxWidth + 56, alignment: .leading)
            }
            .padding(.horizontal, AuthChromeLayout.horizontalPadding)
        }
    }

    private var brandHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(CursorTheme.accent)
                Text("Publshr")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(CursorTheme.foreground)
            }
            Text(auth.screen == .confirmEmail ? "Confirm your email" : "Enterprise workspace for your team")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.bottom, 8)
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            AuthChromeLayout.modeSegment(title: "Sign in", selected: auth.screen == .signIn) {
                auth.screen = .signIn
                auth.errorMessage = nil
                auth.infoMessage = nil
            }
            AuthChromeLayout.modeSegment(title: "Create account", selected: auth.screen == .signUp) {
                auth.screen = .signUp
                auth.errorMessage = nil
                auth.infoMessage = nil
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CursorTheme.editorLineHighlight.opacity(0.5))
        )
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var formContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch auth.screen {
            case .signIn:
                if auth.canOfferBiometricUnlock { biometricRow }
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
                HStack(spacing: 12) {
                    Button("Resend code") { Task { await auth.resendConfirmation() } }
                        .buttonStyle(.borderless)
                        .font(.system(size: 12))
                    Button("Back to sign in") {
                        auth.screen = .signIn
                        auth.otpCode = ""
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 12))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var biometricRow: some View {
        Button { Task { await auth.unlockWithBiometrics() } } label: {
            HStack(spacing: 8) {
                Image(systemName: "touchid")
                Text("Unlock with \(BiometricAuthService.biometricLabel)")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(CursorTheme.biometricTint)
        }
        .buttonStyle(.borderless)
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
        AuthChromeLayout.primaryButton(title: primaryTitle, isLoading: auth.isLoading) {
            Task {
                switch auth.screen {
                case .signIn: await auth.signIn()
                case .signUp: await auth.signUp()
                case .confirmEmail: await auth.confirmEmailOTP()
                }
            }
        }
        .keyboardShortcut(.return, modifiers: .command)
        .padding(.top, 4)
    }

    private var primaryTitle: String {
        switch auth.screen {
        case .signIn: return "Sign in"
        case .signUp: return "Create account"
        case .confirmEmail: return "Verify email"
        }
    }

    private var footerHint: some View {
        Text("Sessions stay active on this Mac. Enable Touch ID in Settings for quick unlock.")
            .font(.system(size: 11))
            .foregroundStyle(CursorTheme.foregroundDim)
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
        AuthChromeLayout.labeledField(label) {
            TextField("", text: text)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: field)
                #if os(macOS)
                .textContentType(contentType)
                #endif
        }
    }

    private func authSecureField(_ label: String, text: Binding<String>, field: Field) -> some View {
        AuthChromeLayout.labeledField(label) {
            SecureField("", text: text)
                .textFieldStyle(.plain)
                .focused($focusedField, equals: field)
        }
    }
}
