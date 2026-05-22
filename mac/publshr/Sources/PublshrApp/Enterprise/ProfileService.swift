import Foundation
import Supabase

@MainActor
enum ProfileService {
    private static let bucket = "workspace-files"
    private static let signedURLExpiry: Int = 60 * 60 * 24 * 7

    /// Upload profile photo; stores storage path in `profiles.avatar_url` (not a public URL).
    static func uploadAvatar(
        client: SupabaseClient,
        userId: UUID,
        data: Data,
        mimeType: String
    ) async throws -> Profile {
        let ext = mimeType.contains("png") ? "png" : "jpg"
        // Path must start with the user's UUID — a leading `avatars/` folder breaks Storage owner_id on some projects.
        let path = "\(userId.uuidString)/avatar.\(ext)"
        _ = try await client.storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: mimeType, upsert: true)
            )
        struct Patch: Encodable {
            let avatar_url: String
        }
        let updated: Profile = try await client
            .from("profiles")
            .update(Patch(avatar_url: path))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    static func updateDisplayName(
        client: SupabaseClient,
        userId: UUID,
        displayName: String
    ) async throws -> Profile {
        struct Patch: Encodable {
            let display_name: String
        }
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated: Profile = try await client
            .from("profiles")
            .update(Patch(display_name: trimmed))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }

    /// Resolves `avatar_url` for display — supports legacy https URLs and storage paths.
    static func resolveAvatarURL(client: SupabaseClient?, avatarUrl: String?) async -> URL? {
        guard let avatarUrl, !avatarUrl.isEmpty else { return nil }
        if avatarUrl.hasPrefix("http://") || avatarUrl.hasPrefix("https://") {
            return URL(string: avatarUrl)
        }
        guard let client else { return nil }
        do {
            let signed = try await client.storage
                .from(bucket)
                .createSignedURL(path: avatarUrl, expiresIn: signedURLExpiry)
            return signed
        } catch {
            return nil
        }
    }
}
