import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case updates, account, workspace, billing, privacy, devices, files, security, chat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .updates: return "Updates"
        case .account: return "Account"
        case .workspace: return "Workspace"
        case .billing: return "Subscription"
        case .privacy: return "Privacy"
        case .devices: return "Devices"
        case .files: return "Files"
        case .security: return "Security"
        case .chat: return "Chat"
        }
    }

    var icon: String {
        switch self {
        case .updates: return "arrow.down.circle"
        case .account: return "person.circle"
        case .workspace: return "building.2"
        case .billing: return "creditcard"
        case .privacy: return "hand.raised"
        case .devices: return "desktopcomputer"
        case .files: return "folder"
        case .security: return "lock.shield"
        case .chat: return "bubble.left.and.bubble.right"
        }
    }
}

/// Settings — single nav column + detail (no duplicate shell sidebar).
struct SettingsRootView: View {
    @State private var selection: SettingsSection = .updates

    var body: some View {
        HStack(spacing: 0) {
            settingsNavColumn
                .frame(width: CursorTheme.settingsSidebarWidth)
                .background(settingsNavBackground)

            Rectangle()
                .fill(CursorTheme.border.opacity(0.45))
                .frame(width: 1)

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .onAppear {
            if let pending = WorkspaceModuleWindowManager.shared.consumePendingSettingsSection() {
                selection = pending
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .publshrOpenSettings)) { output in
            if let raw = output.object as? String, let section = SettingsSection(rawValue: raw) {
                selection = section
            }
        }
    }

    private var settingsNavBackground: some View {
        ZStack {
            Color(hex: 0xF5F5F3)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.55),
                    Color(hex: 0xF0F0EE).opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var settingsNavColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsSection.allCases) { section in
                    EnterpriseSidebarRow(
                        title: section.title,
                        icon: section.icon,
                        selected: selection == section
                    ) {
                        selection = section
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .updates: SettingsUpdatesPane()
        case .account: SettingsAccountPane()
        case .workspace: SettingsWorkspacePane()
        case .billing: SettingsBillingPane()
        case .privacy: SettingsPrivacyPane()
        case .devices: SettingsDevicesPane()
        case .files: SettingsFilesPane()
        case .security: SettingsSecurityPane()
        case .chat: SettingsChatPane()
        }
    }
}
