import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var chat: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
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

                    header("About")
                    aboutSection

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

            liveUpdateFooter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CursorTheme.editorBackground)
        .onAppear {
            Task { await updates.performLiveSync() }
        }
    }

    // MARK: - Pinned live update footer

    private var liveUpdateFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if updates.isActivelyUpdating {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(updates.statusLine)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CursorTheme.foreground)
                    .lineLimit(2)
            }

            if let err = updates.errorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Installed: \(AppReleaseConfig.installedLabel) · Live checks every minute (icon, UI, features — any push to main).")
                .font(.system(size: 10))
                .foregroundStyle(CursorTheme.foregroundDim)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await updates.installLiveUpdateNow() }
            } label: {
                Text(updates.settingsActionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(updateActionBusy)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(CursorTheme.panelBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(CursorTheme.border)
                .frame(height: 1)
        }
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

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            labeledRow("Shell", AppShellIdentity.distributionTag)
            labeledRow("Bundle", Bundle.main.bundleURL.lastPathComponent)
            if Bundle.main.object(forInfoDictionaryKey: "PublshrShellVersion") as? String != "enterprise-4" {
                Text("This build is outdated. Use the button below to install the latest live release.")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .fixedSize(horizontal: false, vertical: true)
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
