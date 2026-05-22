import Foundation
import Supabase

@MainActor
final class EnterpriseWorkspaceService: ObservableObject {
    @Published private(set) var devices: [DeviceRegistrationRow] = []
    @Published var inviteEmail = ""
    @Published var errorMessage: String?

    struct DeviceRegistrationRow: Codable, Identifiable, Equatable {
        let id: UUID
        let userId: UUID
        let deviceKey: String
        let deviceName: String
        let platform: String
        let appVersion: String
        let lastSeenAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case deviceKey = "device_key"
            case deviceName = "device_name"
            case platform
            case appVersion = "app_version"
            case lastSeenAt = "last_seen_at"
        }

        var isThisDevice: Bool {
            deviceKey == DeviceIdentityService.current.deviceKey
        }
    }

    func updateWorkspaceSettings(client: SupabaseClient, workspaceId: UUID, settings: [String: JSONValue]) async throws {
        struct Patch: Encodable {
            let settings: [String: JSONValue]
        }
        try await client
            .from("workspaces")
            .update(Patch(settings: settings))
            .eq("id", value: workspaceId.uuidString)
            .execute()
    }

    func persistChatPermissions(
        client: SupabaseClient,
        workspace: inout Workspace,
        permissions: ChatWorkspacePermissions
    ) async throws {
        var chatSettings: [String: JSONValue] = [:]
        chatSettings["can_create_channels"] = .bool(permissions.canCreateChannels)
        chatSettings["can_dm"] = .bool(permissions.canDM)
        chatSettings["can_use_voice_notes"] = .bool(permissions.canUseVoiceNotes)
        chatSettings["read_receipts_enabled"] = .bool(permissions.readReceiptsEnabled)
        chatSettings["can_upload_files"] = .bool(permissions.canUploadFiles)
        chatSettings["can_pin_messages"] = .bool(permissions.canPinMessages)
        chatSettings["can_export_chats"] = .bool(permissions.canExportChats)
        var settings = workspace.settings ?? [:]
        settings["chat"] = .object(chatSettings)
        try await updateWorkspaceSettings(client: client, workspaceId: workspace.id, settings: settings)
        workspace.settings = settings
    }

    func loadDevices(client: SupabaseClient, userId: UUID) async {
        do {
            devices = try await client
                .from("device_registrations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("last_seen_at", ascending: false)
                .execute()
                .value
        } catch {
            devices = []
        }
    }

    func inviteMember(client: SupabaseClient, workspaceId: UUID, email: String, role: String = "member") async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        do {
            let profiles: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("email", value: trimmed)
                .limit(1)
                .execute()
                .value
            guard let profile = profiles.first else {
                errorMessage = "No user with that email. They must sign up first, then you can add them."
                return
            }
            struct Insert: Encodable {
                let workspace_id: UUID
                let user_id: UUID
                let role: String
            }
            try await client
                .from("workspace_members")
                .insert(Insert(workspace_id: workspaceId, user_id: profile.id, role: role))
                .execute()
            inviteEmail = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
