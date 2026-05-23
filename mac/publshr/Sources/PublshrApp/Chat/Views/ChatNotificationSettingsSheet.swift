import SwiftUI

/// ClickUp-style notification defaults — All, Mentions only, Mute (per user, local + channel member API).
struct ChatNotificationSettingsSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notification settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("These preferences apply to you in this workspace. Channel-specific overrides are in each channel’s settings.")
                        .font(.system(size: 12))
                        .foregroundStyle(CursorTheme.foregroundMuted)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default for new channels")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                        Picker("Notify me", selection: Binding(
                            get: { chat.defaultNotificationLevel },
                            set: { chat.setDefaultNotificationLevel($0) }
                        )) {
                            Text("All messages").tag("all")
                            Text("Mentions only").tag("mentions")
                            Text("Mute").tag("muted")
                        }
                        .pickerStyle(.segmented)
                    }

                    if let channel = chat.selectedChannel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current channel — \(channel.sidebarTitle)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                            let level = chat.myChannelMemberRecord()?.notificationLevel ?? "all"
                            HStack(spacing: 8) {
                                notificationQuickButton("All", level: "all", current: level, channel: channel)
                                notificationQuickButton("Mentions", level: "mentions", current: level, channel: channel)
                                notificationQuickButton("Mute", level: "muted", current: level, channel: channel)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Desktop alerts")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                        Toggle("macOS Notification Center", isOn: macNotificationsBinding)
                        Toggle("Floating message preview (Teams-style)", isOn: incomingPopupBinding)
                        Toggle("Open channel window from preview", isOn: popupOpensWindowBinding)
                            .disabled(!chat.showIncomingMessagePopup)
                        Toggle("Timestamps in my local timezone", isOn: localTimeZoneBinding)
                        Toggle("Play sound on new message", isOn: messageSoundBinding)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Inbox")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                        Button {
                            chat.markAllChannelsRead()
                        } label: {
                            Label("Mark all conversations read", systemImage: "checkmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 440, height: 480)
    }

    private var macNotificationsBinding: Binding<Bool> {
        Binding(
            get: { chat.macNotificationsEnabled },
            set: { chat.macNotificationsEnabled = $0 }
        )
    }

    private var incomingPopupBinding: Binding<Bool> {
        Binding(
            get: { chat.showIncomingMessagePopup },
            set: { chat.showIncomingMessagePopup = $0 }
        )
    }

    private var popupOpensWindowBinding: Binding<Bool> {
        Binding(
            get: { chat.popupOpensChannelWindow },
            set: { chat.popupOpensChannelWindow = $0 }
        )
    }

    private var localTimeZoneBinding: Binding<Bool> {
        Binding(
            get: { chat.showTimestampsInLocalTimeZone },
            set: { chat.showTimestampsInLocalTimeZone = $0 }
        )
    }

    private var messageSoundBinding: Binding<Bool> {
        Binding(
            get: { chat.playMessageSound },
            set: { chat.playMessageSound = $0 }
        )
    }

    private func notificationQuickButton(
        _ title: String,
        level: String,
        current: String,
        channel: ChatChannel
    ) -> some View {
        let selected = current == level
        return Button {
            chat.selectChannel(channel)
            Task { await chat.setSelectedChannelNotificationLevel(level) }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selected ? Color.white : CursorTheme.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? CursorTheme.accent : CursorTheme.buttonBackground)
                )
        }
        .buttonStyle(.plain)
    }
}
