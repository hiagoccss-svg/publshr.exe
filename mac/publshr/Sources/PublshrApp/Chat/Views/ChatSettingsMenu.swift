import SwiftUI

/// Chat settings gear — workspace, app, and channel (when a channel is selected) only.
enum ChatSettingsMenu {
    @ViewBuilder
    static func items(chat: ChatViewModel) -> some View {
        Button {
            NotificationCenter.default.post(
                name: .publshrOpenSettings,
                object: SettingsSection.workspace.rawValue
            )
        } label: {
            Label("Workspace settings", systemImage: "building.2")
        }

        Button {
            NotificationCenter.default.post(
                name: .publshrOpenSettings,
                object: SettingsSection.account.rawValue
            )
        } label: {
            Label("App settings", systemImage: "gearshape")
        }

        if chat.selectedChannel != nil {
            Button {
                chat.showChannelSettings = true
            } label: {
                Label(channelSettingsTitle(chat: chat), systemImage: "gearshape")
            }
        }
    }

    private static func channelSettingsTitle(chat: ChatViewModel) -> String {
        guard let channel = chat.selectedChannel else { return "Channel settings" }
        if channel.kind == .dm || channel.kind == .group {
            return "Conversation settings"
        }
        return "Channel settings"
    }
}
