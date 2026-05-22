import SwiftUI

/// Choose or create a workspace — permissions vary by role.
struct WorkspacePickerView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ZStack {
            CursorTheme.authBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                VStack(spacing: 24) {
                    header
                    pickerCard
                }
                .frame(maxWidth: 480)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 40)
        }
        .preferredColorScheme(.light)
        .task { await auth.loadWorkspaces() }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Choose workspace")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text("Your role controls chat, channels, and admin access.")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var pickerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if auth.workspaceMemberships.isEmpty {
                emptyState
            } else {
                ForEach(auth.workspaceMemberships) { membership in
                    workspaceRow(membership)
                }
            }

            Divider().overlay(CursorTheme.border)

            createSection

            if let error = auth.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.error)
            }

            Button {
                Task { await auth.confirmWorkspaceSelection() }
            } label: {
                Text("Continue to Publshr")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(CursorTheme.buttonForeground)
                    .background(
                        auth.selectedMembership == nil
                            ? CursorTheme.buttonBackground.opacity(0.4)
                            : CursorTheme.buttonBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(auth.selectedMembership == nil || auth.isLoading)

            Button("Sign out") { Task { await auth.signOut() } }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .frame(maxWidth: .infinity)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(CursorTheme.authCard)
                .shadow(color: CursorTheme.authCardShadow, radius: 16, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(CursorTheme.border, lineWidth: 1)
        )
    }

    private func workspaceRow(_ membership: WorkspaceMembership) -> some View {
        let selected = auth.selectedMembership?.id == membership.id
        return Button {
            auth.selectedMembership = membership
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CursorTheme.sideBar)
                        .frame(width: 40, height: 40)
                    Text(String(membership.workspace.name.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(CursorTheme.accent)
                }
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
                roleBadge(membership.role)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CursorTheme.accent)
                }
            }
            .padding(12)
            .background(selected ? CursorTheme.accent.opacity(0.06) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? CursorTheme.accent.opacity(0.4) : CursorTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func roleBadge(_ role: WorkspaceRole) -> some View {
        Text(role.label)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(CursorTheme.sideBar)
            .clipShape(Capsule())
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
        VStack(alignment: .leading, spacing: 8) {
            Text("No workspace yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
            Text("Create one for your team — you'll be the owner with full permissions.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create new workspace")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
            HStack(spacing: 8) {
                TextField("Company or team name", text: $auth.newWorkspaceName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(CursorTheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(CursorTheme.inputBorder, lineWidth: 1)
                    )
                Button {
                    Task { await auth.createWorkspaceAndContinue() }
                } label: {
                    Text("Create")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(CursorTheme.buttonForeground)
                        .background(CursorTheme.buttonBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(auth.isCreatingWorkspace || auth.newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}
