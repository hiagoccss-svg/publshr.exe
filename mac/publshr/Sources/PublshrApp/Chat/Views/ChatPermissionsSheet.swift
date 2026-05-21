import SwiftUI

struct ChatPermissionsSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Workspace permissions") {
                Toggle("Create channels", isOn: $chat.permissions.canCreateChannels)
                Toggle("Create group chats", isOn: $chat.permissions.canCreateGroupChats)
                Toggle("Direct messages", isOn: $chat.permissions.canDM)
                Toggle("Invite users", isOn: $chat.permissions.canInviteUsers)
                Toggle("Add guests", isOn: $chat.permissions.canAddGuests)
            }
            Section("Messages & content") {
                Toggle("Edit messages", isOn: $chat.permissions.canEditMessages)
                Toggle("Delete messages", isOn: $chat.permissions.canDeleteMessages)
                Toggle("Pin messages", isOn: $chat.permissions.canPinMessages)
                Toggle("Upload files", isOn: $chat.permissions.canUploadFiles)
                Toggle("Voice notes", isOn: $chat.permissions.canUseVoiceNotes)
                Toggle("Export chats", isOn: $chat.permissions.canExportChats)
            }
            Section("Privacy") {
                Toggle("Read receipts", isOn: $chat.permissions.readReceiptsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await chat.savePermissionsToWorkspace()
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
