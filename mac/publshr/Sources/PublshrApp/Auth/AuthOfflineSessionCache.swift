import Foundation

/// Last-known profile, workspaces, and permissions for offline biometric entry.
enum AuthOfflineSessionCache {
    struct MembershipRow: Codable {
        let workspace: Workspace
        let role: String
    }

    struct Snapshot: Codable {
        let profile: Profile
        let memberships: [MembershipRow]
        let selectedWorkspaceId: UUID?
        let savedAt: Date
    }

    private static var fileURL: URL {
        LocalDataLayout.ensureRootExists()
        return LocalDataLayout.authOfflineSnapshot
    }

    static func save(
        profile: Profile?,
        memberships: [WorkspaceMembership],
        selectedWorkspaceId: UUID?
    ) {
        guard let profile else { return }
        let rows = memberships.map { MembershipRow(workspace: $0.workspace, role: $0.role.rawValue) }
        let snap = Snapshot(
            profile: profile,
            memberships: rows,
            selectedWorkspaceId: selectedWorkspaceId,
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snap) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return nil
        }
        return snap
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func memberships(from snap: Snapshot) -> [WorkspaceMembership] {
        snap.memberships.compactMap { row in
            guard let role = WorkspaceRole(rawValue: row.role) else { return nil }
            return WorkspaceMembership(workspace: row.workspace, role: role)
        }
    }
}
