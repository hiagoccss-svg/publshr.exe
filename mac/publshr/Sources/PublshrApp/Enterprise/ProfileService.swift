import Foundation
import Supabase

@MainActor
enum ProfileService {
    private static let bucket = "workspace-files"

    static func uploadAvatar(
        client: SupabaseClient,
        userId: UUID,
        data: Data,
        mimeType: String
    ) async throws -> Profile {
        let ext = mimeType.contains("png") ? "png" : "jpg"
        let path = "avatars/\(userId.uuidString).\(ext)"
        _ = try await client.storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(contentType: mimeType, upsert: true)
            )
        let publicURL = try client.storage.from(bucket).getPublicURL(path: path)
        struct Patch: Encodable {
            let avatar_url: String
        }
        let updated: Profile = try await client
            .from("profiles")
            .update(Patch(avatar_url: publicURL.absoluteString))
            .eq("id", value: userId.uuidString)
            .select()
            .single()
            .execute()
            .value
        return updated
    }
}
