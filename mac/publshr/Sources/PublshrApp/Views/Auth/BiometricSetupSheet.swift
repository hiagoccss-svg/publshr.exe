import SwiftUI

/// One-time offer after first sign-in to enable Touch ID / Face ID quick unlock.
struct BiometricSetupSheet: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "touchid")
                    .font(.system(size: 32))
                    .foregroundStyle(CursorTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable \(BiometricAuthService.biometricLabel)?")
                        .font(.headline)
                    Text("Unlock Publshr quickly on this Mac without typing your password each time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Button("Not now") {
                    auth.dismissBiometricSetupOffer(enable: false)
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Enable") {
                    auth.dismissBiometricSetupOffer(enable: true)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
