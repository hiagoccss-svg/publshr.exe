import SwiftUI

/// Choose or create a workspace — native card layout on auth background.
struct WorkspacePickerView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ZStack {
            AuthChromeLayout.screenBackground

            VStack(spacing: 0) {
                Color.clear.frame(height: AuthChromeLayout.topChromeInset)
                Spacer(minLength: 24)

                AuthChromeLayout.card {
                    header
                    workspaceList
                    createSection

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundStyle(CursorTheme.error)
                    }

                    AuthChromeLayout.primaryButton(
                        title: "Continue",
                        isLoading: auth.isLoading
                    ) {
                        Task { await auth.confirmWorkspaceSelection() }
                    }
                    .disabled(auth.selectedMembership == nil)

                    AuthChromeLayout.secondaryButton(title: "Sign out") {
                        Task { await auth.signOut() }
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, AuthChromeLayout.horizontalPadding)
        }
        .task { await auth.loadWorkspaces() }
        .overlay {
            if auth.isLoading && auth.workspaceMemberships.isEmpty {
                ProgressView("Loading workspaces…")
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            Text("Your role controls chat, channels, and admin access.")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var workspaceList: some View {
        if auth.workspaceMemberships.isEmpty {
            emptyState
        } else {
            VStack(spacing: 4) {
                ForEach(auth.workspaceMemberships) { membership in
                    workspaceRow(membership)
                }
            }
            .padding(.vertical, 4)
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
                    .foregroundStyle(CursorTheme.buttonForeground)
                    .frame(width: 36, height: 36)
                    .background(CursorTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CursorTheme.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? CursorTheme.accent.opacity(0.08) : CursorTheme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(selected ? CursorTheme.accent.opacity(0.35) : CursorTheme.inputBorder, lineWidth: 1)
            )
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
                .foregroundStyle(CursorTheme.foregroundMuted)
            HStack(spacing: 10) {
                AuthChromeLayout.labeledField("Name") {
                    TextField("Company or team name", text: $auth.newWorkspaceName)
                        .textFieldStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                Button {
                    Task { await auth.createWorkspaceAndContinue() }
                } label: {
                    Text("Create")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CursorTheme.buttonForeground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(CursorTheme.buttonBackground)
                        )
                }
                .buttonStyle(.plain)
                .disabled(auth.isCreatingWorkspace || auth.newWorkspaceName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.vertical, 4)
    }
}
