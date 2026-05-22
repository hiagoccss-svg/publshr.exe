import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ZStack {
            CursorTheme.activityBar.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 80)

                VStack(spacing: 24) {
                    brandHeader
                    authCard
                }
                .frame(maxWidth: 420)

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 32)
        }
    }

    private var brandHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
            Text("Publshr")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text("Sign in to continue")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private var authCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if auth.screen != .confirmEmail {
                tabSwitcher
            }

            switch auth.screen {
            case .signIn:
                signInForm
            case .signUp:
                signUpForm
            case .confirmEmail:
                confirmForm
            }

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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CursorTheme.authCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CursorTheme.border, lineWidth: 1)
                )
        )
    }

    private var tabSwitcher: some View {
        HStack(spacing: 0) {
            authTab("Sign in", screen: .signIn)
            authTab("Create account", screen: .signUp)
        }
        .background(CursorTheme.editorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
    }

    private func authTab(_ title: String, screen: AuthScreen) -> some View {
        Button {
            auth.screen = screen
            auth.errorMessage = nil
            auth.infoMessage = nil
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(auth.screen == screen ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                .background(auth.screen == screen ? CursorTheme.sideBar : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var signInForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            authField("Email", text: $auth.email, contentType: authEmailContentType)
            authSecureField("Password", text: $auth.password)
            primaryButton("Sign in", action: { Task { await auth.signIn() } })
        }
    }

    private var signUpForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            authField("Name", text: $auth.displayName)
            authField("Email", text: $auth.email, contentType: authEmailContentType)
            authSecureField("Password", text: $auth.password)
            Text("At least 8 characters")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
            primaryButton("Create account", action: { Task { await auth.signUp() } })
        }
    }

    private var confirmForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confirm your email")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text("Enter the 6-digit code sent to \(auth.email)")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .fixedSize(horizontal: false, vertical: true)

            authField("Code", text: $auth.otpCode, contentType: authOTPContentType)

            primaryButton("Verify email", action: { Task { await auth.confirmEmailOTP() } })

            HStack {
                Button("Resend code") { Task { await auth.resendConfirmation() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
                Spacer()
                Button("Back to sign in") {
                    auth.screen = .signIn
                    auth.otpCode = ""
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
    }

    private var authEmailContentType: NSTextContentType? {
        if #available(macOS 14.0, *) { return .emailAddress }
        return .username
    }

    private var authOTPContentType: NSTextContentType? {
        if #available(macOS 14.0, *) { return .oneTimeCode }
        return nil
    }

    private func authField(_ label: String, text: Binding<String>, contentType: NSTextContentType? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CursorTheme.inputBorder, lineWidth: 1)
                )
                #if os(macOS)
                .textContentType(contentType)
                #endif
        }
    }

    private func authSecureField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            SecureField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CursorTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CursorTheme.inputBorder, lineWidth: 1)
                )
        }
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if auth.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .foregroundStyle(.white)
            .background(auth.isLoading ? CursorTheme.buttonBackground.opacity(0.7) : CursorTheme.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .disabled(auth.isLoading)
    }
}
