import SwiftUI
import PublshrCore

struct RootView: View {
    @ObservedObject private var supabase = SupabaseService.shared
    @StateObject private var model = AppModel()
    @State private var biometricUnlocked = false

    var body: some View {
        Group {
            if !supabase.isAuthenticated {
                LoginView()
            } else if BiometricGate.isEnabled && !biometricUnlocked {
                BiometricUnlockView { biometricUnlocked = true }
            } else {
                AppShellView()
                    .environmentObject(model)
            }
        }
        .onChange(of: supabase.isAuthenticated) { _, authed in
            if authed { biometricUnlocked = !BiometricGate.isEnabled }
            else { biometricUnlocked = false }
        }
    }
}
