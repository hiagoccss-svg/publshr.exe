import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainIDEView()
            } else {
                AuthView()
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(CursorTheme.editorBackground)
    }
}
