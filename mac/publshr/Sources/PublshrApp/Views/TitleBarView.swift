import SwiftUI

/// Content-area header only (not over activity bar or nav sidebar).
struct TitleBarView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var chat: ChatViewModel
    var module: AppModule

    var body: some View {
        HStack(spacing: 12) {
            Text(module.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
                .frame(minWidth: 72, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundDim)
                TextField(searchPlaceholder, text: searchBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CursorTheme.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CursorTheme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: 420)

            Spacer()

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
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .background(CursorTheme.titleBar)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    private var searchPlaceholder: String {
        switch module {
        case .chat: return "Search channels, DMs, and messages"
        case .spaces: return "Search spaces and tasks"
        case .settings: return "Search settings"
        }
    }

    private var searchBinding: Binding<String> {
        switch module {
        case .chat:
            return Binding(
                get: { chat.searchQuery },
                set: { chat.searchQuery = $0 }
            )
        case .spaces, .settings:
            return .constant("")
        }
    }
}
