import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("Supabase connected")
                    .font(.system(size: 11))
            }

            if let profile = auth.profile {
                Text(profile.email)
                    .font(.system(size: 11))
                    .lineLimit(1)
            }

            Spacer()

            Text("UTF-8")
                .font(.system(size: 11))
            Text("Swift")
                .font(.system(size: 11))
            Text("Ln 1, Col 1")
                .font(.system(size: 11))
        }
        .padding(.horizontal, 12)
        .foregroundStyle(CursorTheme.statusBarForeground.opacity(0.95))
        .background(CursorTheme.statusBar)
    }
}
