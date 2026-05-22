import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var updates: AppUpdateViewModel
    @EnvironmentObject private var chat: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header("Supabase")
                    supabaseSection

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
            Task {
                await auth.loadProfile()
                await auth.refreshSupabaseConnection()
                await updates.performLiveSync()
            }
        }
    }

    private var supabaseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            labeledRow("Status", auth.supabaseStatusLine)
            labeledRow("Project", SupabaseConfig.displayHost)
            labeledRow("API key", SupabaseConfig.publishableKeySuffix)
            if let uid = auth.session?.user.id {
                labeledRow("User ID", uid.uuidString)
            }
            if auth.session != nil {
                labeledRow("Session", "Active")
            }
            Button {
                Task { await auth.refreshSupabaseConnection() }
            } label: {
                HStack(spacing: 6) {
                    if auth.isRefreshingConnection {
                        ProgressView().controlSize(.small)
                    }
                    Text("Refresh connection")
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(CursorTheme.accent)
            .disabled(auth.isRefreshingConnection)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Software updates

    private var liveUpdateFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Software updates")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
                .tracking(0.5)

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

            if let err = updates.settingsErrorMessage {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("GitHub and Supabase sync automatically every minute. Updates install in place — no separate installer. Build \(AppReleaseConfig.buildNumber).")
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
            Text("Use Software updates below to install the latest version from your organization.")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .fixedSize(horizontal: false, vertical: true)
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
            Text("When enabled, \(BiometricAuthService.biometricLabel) is required each time you open Publshr. Your password is still used for first sign-in.")
                .font(.system(size: 11))
                .foregroundStyle(CursorTheme.foregroundDim)
                .fixedSize(horizontal: false, vertical: true)

            if BiometricAuthService.isAvailable {
                Toggle(isOn: Binding(
                    get: { auth.biometricUnlockEnabled },
                    set: { auth.setBiometricUnlockEnabled($0) }
                )) {
                    Text("Quick unlock with \(BiometricAuthService.biometricLabel)")
                        .font(.system(size: 12))
                }
                .toggleStyle(.switch)
            } else {
                Text("\(BiometricAuthService.biometricLabel) is not available on this Mac.")
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
