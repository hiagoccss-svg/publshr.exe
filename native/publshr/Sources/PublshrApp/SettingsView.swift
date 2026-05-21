import SwiftUI
import PublshrCore

struct SettingsView: View {
    @ObservedObject private var supabase = SupabaseService.shared

    var body: some View {
        TabView {
            Form {
                Toggle("Unlock with Touch ID / Face ID", isOn: Binding(
                    get: { BiometricGate.isEnabled },
                    set: { BiometricGate.isEnabled = $0 }
                ))
                .disabled(!BiometricGate.canUseBiometrics)
                Text("Biometrics lock the app on this Mac. Sign-in still uses Supabase.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .formStyle(.grouped)
            .tabItem { Label("Security", systemImage: "lock") }

            Form {
                LabeledContent("Supabase") {
                    Text(SupabaseConfig.url.absoluteString)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                LabeledContent("Account") {
                    Text(supabase.profile?.email ?? "—")
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Account", systemImage: "person") }
        }
        .frame(width: 440, height: 280)
    }
}
