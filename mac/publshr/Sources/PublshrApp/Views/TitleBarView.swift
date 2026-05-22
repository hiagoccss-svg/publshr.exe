import SwiftUI

struct TitleBarView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Traffic-light spacer (macOS draws native controls in hidden title bar)
            Color.clear.frame(width: 70, height: 1)

            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)

            Text("Search files, commands, and more")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(CursorTheme.inputBackground.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if !auth.workspaceMemberships.isEmpty {
                Menu {
                    ForEach(auth.workspaceMemberships) { m in
                        Button {
                            auth.switchWorkspace(m)
                        } label: {
                            Text("\(m.workspace.name) · \(m.role.label)")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(auth.selectedMembership?.workspace.name ?? "Workspace")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(CursorTheme.foregroundMuted)
                }
                .menuStyle(.borderlessButton)
            }
            if let profile = auth.profile {
                Text(profile.displayName ?? profile.email)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
                    .lineLimit(1)
            }

            Button {
                Task { await auth.signOut() }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .buttonStyle(.plain)
            .help("Sign out")
        }
        .padding(.trailing, 12)
        .background(CursorTheme.titleBar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }
}
