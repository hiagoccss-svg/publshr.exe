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

/// Native macOS Settings layout — sidebar list + detail pane (System Settings pattern).
struct SettingsRootView: View {
    @State private var selection: SettingsSection = .updates

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(SettingsSection.allCases) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .frame(minWidth: 200)
            .onReceive(NotificationCenter.default.publisher(for: .publshrOpenSettings)) { output in
                if let raw = output.object as? String, let section = SettingsSection(rawValue: raw) {
                    selection = section
                }
            }
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
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
