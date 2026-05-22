import SwiftUI

struct ChatPermissionsSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var saveTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section {
                Text("These settings apply to your workspace. Changes save automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Workspace permissions") {
                permissionToggle("Create channels", \.canCreateChannels)
                permissionToggle("Create group chats", \.canCreateGroupChats)
                permissionToggle("Direct messages", \.canDM)
                permissionToggle("Invite users", \.canInviteUsers)
                permissionToggle("Add guests", \.canAddGuests)
            }
            Section("Messages & content") {
                permissionToggle("Edit messages", \.canEditMessages)
                permissionToggle("Delete messages", \.canDeleteMessages)
                permissionToggle("Pin messages", \.canPinMessages)
                permissionToggle("Upload files", \.canUploadFiles)
                permissionToggle("Voice notes", \.canUseVoiceNotes)
                permissionToggle("Export chats", \.canExportChats)
            }
            Section("Privacy") {
                permissionToggle("Read receipts", \.readReceiptsEnabled)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 480)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onDisappear {
            saveTask?.cancel()
            Task { await chat.savePermissionsToWorkspace() }
        }
    }

    private func permissionToggle(
        _ title: String,
        _ path: WritableKeyPath<ChatWorkspacePermissions, Bool>
    ) -> some View {
        Toggle(title, isOn: Binding(
            get: { chat.permissions[keyPath: path] },
            set: { newValue in
                chat.permissions[keyPath: path] = newValue
                scheduleSave()
            }
        ))
    }

    private func scheduleSave() {
        if let ws = chat.workspace {
            ChatUserPreferences.cachePermissions(chat.permissions, workspaceId: ws.id)
        }
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            await chat.savePermissionsToWorkspace()
        }
    }
}
