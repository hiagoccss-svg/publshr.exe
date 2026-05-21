import Foundation

enum WorkspaceRole: String, Codable, CaseIterable {
    case owner
    case admin
    case member
    case viewer

    var label: String {
        rawValue.capitalized
    }

    var canManageWorkspace: Bool {
        self == .owner || self == .admin
    }
}

struct WorkspaceMembership: Identifiable, Equatable {
    let workspace: Workspace
    let role: WorkspaceRole

    var id: UUID { workspace.id }

    /// Effective chat permissions = workspace JSON settings merged with role caps.
    func chatPermissions() -> ChatWorkspacePermissions {
        var p = ChatWorkspacePermissions.default
        if let chat = workspace.settings?["chat"], case .object(let obj) = chat {
            func bool(_ key: String, _ path: WritableKeyPath<ChatWorkspacePermissions, Bool>) {
                if case .bool(let v) = obj[key] { p[keyPath: path] = v }
            }
            bool("can_create_channels", \.canCreateChannels)
            bool("can_dm", \.canDM)
            bool("can_use_voice_notes", \.canUseVoiceNotes)
            bool("read_receipts_enabled", \.readReceiptsEnabled)
            bool("can_upload_files", \.canUploadFiles)
            bool("can_pin_messages", \.canPinMessages)
            bool("can_export_chats", \.canExportChats)
            bool("can_invite_users", \.canInviteUsers)
            bool("can_add_guests", \.canAddGuests)
        }
        switch role {
        case .owner, .admin:
            break
        case .member:
            p.canInviteUsers = false
            p.canAddGuests = false
            p.canExportChats = false
        case .viewer:
            p.canCreateChannels = false
            p.canCreateGroupChats = false
            p.canDM = false
            p.canDeleteMessages = false
            p.canEditMessages = false
            p.canPinMessages = false
            p.canUploadFiles = false
            p.canUseVoiceNotes = false
            p.canInviteUsers = false
            p.canAddGuests = false
            p.canExportChats = false
        }
        return p
    }
}
