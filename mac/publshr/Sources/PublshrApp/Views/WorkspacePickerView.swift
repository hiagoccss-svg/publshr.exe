import SwiftUI

/// Choose or create a workspace — borderless macOS layout.
struct WorkspacePickerView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ZStack {
            CursorTheme.activityBar.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(alignment: .leading, spacing: 24) {
                    header
                    workspaceList
                    createSection

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(CursorTheme.error)
                    }

                    continueButton

                    Button("Sign out") { Task { await auth.signOut() } }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                .frame(maxWidth: 420, alignment: .leading)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 48)
        }
        .task { await auth.loadWorkspaces() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text("Your role controls chat, channels, and admin access.")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    @ViewBuilder
    private var workspaceList: some View {
        if auth.workspaceMemberships.isEmpty {
            emptyState
        } else {
            VStack(spacing: 2) {
                ForEach(auth.workspaceMemberships) { membership in
                    workspaceRow(membership)
                }
            }
        }
    }

    private func workspaceRow(_ membership: WorkspaceMembership) -> some View {
        let selected = auth.selectedMembership?.id == membership.id
        return Button {
            auth.selectedMembership = membership
        } label: {
            HStack(spacing: 12) {
                Text(String(membership.workspace.name.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CursorTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(CursorTheme.editorLineHighlight.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(membership.workspace.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CursorTheme.foreground)
                    Text(permissionSummary(membership))
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(1)
                }
                Spacer()
                Text(membership.role.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CursorTheme.foregroundDim)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CursorTheme.accent)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(selected ? CursorTheme.accent.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func permissionSummary(_ m: WorkspaceMembership) -> String {
        let p = m.chatPermissions()
        var parts: [String] = []
        if p.canCreateChannels { parts.append("channels") }
        if p.canDM { parts.append("DMs") }
        if p.canUploadFiles { parts.append("files") }
        if m.role == .viewer { return "View only" }
        return parts.isEmpty ? m.role.label : parts.joined(separator: " · ")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No workspace yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
            Text("Create one for your team — you'll be the owner with full permissions.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.vertical, 8)
    }

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create workspace")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
            HStack(spacing: 12) {
                TextField("Company or team name", text: $auth.newWorkspaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(.vertical, 6)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(CursorTheme.border.opacity(0.6)).frame(height: 1)
                    }
                Button {
                    Task { await auth.createWorkspaceAndContinue() }
                } label: {
                    Text("Create")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(auth.isCreatingWorkspace || auth.newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var continueButton: some View {
        Button {
            Task { await auth.confirmWorkspaceSelection() }
        } label: {
            Text("Continue")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(auth.selectedMembership == nil ? CursorTheme.foregroundDim : CursorTheme.accent)
        }
        .buttonStyle(.plain)
        .disabled(auth.selectedMembership == nil || auth.isLoading)
    }
}
