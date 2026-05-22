import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var chat: ChatViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header("App updates")
                updatesSection

                divider

                header("Account")
                accountSection

                divider

                header("Workspace")
                workspaceSection

                divider

                header("Security")
                securitySection

                divider

                header("Chat")
                chatSection

                divider

                Button(role: .destructive) {
                    Task { await auth.signOut() }
                } label: {
                    Text("Sign out")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(CursorTheme.error)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CursorTheme.editorBackground)
    }

    private func header(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CursorTheme.foregroundDim)
            .tracking(0.6)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(CursorTheme.border)
            .frame(height: 1)
            .padding(.horizontal, 20)
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(updates.statusLine)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foreground)

            if let err = updates.errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if Bundle.main.object(forInfoDictionaryKey: "PublshrShellVersion") as? String != "enterprise-3" {
                Text("Your app is an older build (fake Explorer UI). Use Download and install to get Chat and Spaces.")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Button("Check for updates") {
                    Task { await updates.checkForUpdates(silent: false) }
                }
                .buttonStyle(.bordered)

                Button("Download and install") {
                    Task { await updates.updateNow() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(updateActionBusy)
            }

            Text("Updates install from the GitHub live channel (same build as install-macos.sh). After install, the app restarts automatically.")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("Check automatically every 10 minutes", isOn: $updates.autoCheckEnabled)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .onChange(of: updates.autoCheckEnabled) { _, enabled in
                    if enabled {
                        updates.startAutomaticChecks()
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let profile = auth.profile {
                labeledRow("Name", profile.displayName ?? "—")
                labeledRow("Email", profile.email)
            } else {
                Text("Not signed in")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var workspaceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let ws = auth.selectedWorkspace {
                labeledRow("Current", ws.name)
            }
            if !auth.workspaceMemberships.isEmpty {
                Menu("Switch workspace") {
                    ForEach(auth.workspaceMemberships) { m in
                        Button(m.workspace.name) {
                            auth.switchWorkspace(m)
                        }
                    }
                }
                .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if BiometricAuthService.isAvailable {
                Text("Use \(BiometricAuthService.biometricLabel) to unlock without your password.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                if auth.prefersBiometricUnlock {
                    Label("\(BiometricAuthService.biometricLabel) enabled", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.success)
                } else {
                    Button("Enable \(BiometricAuthService.biometricLabel)") {
                        auth.persistSessionToKeychain()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("Biometric unlock is available on Macs with Touch ID.")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Workspace chat permissions…") {
                chat.showPermissionsSheet = true
            }
            .buttonStyle(.bordered)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var updateActionBusy: Bool {
        switch updates.phase {
        case .checking, .downloading, .installing:
            return true
        default:
            return false
        }
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundDim)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(2)
        }
    }
}
