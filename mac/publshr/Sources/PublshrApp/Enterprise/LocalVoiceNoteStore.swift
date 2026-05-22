import Foundation

/// Saves voice notes to Application Support — no upload API required.
enum LocalVoiceNoteStore {
    static func saveRecording(from tempURL: URL, workspaceId: UUID, channelId: UUID) throws -> URL {
        let dir = baseDirectory(workspaceId: workspaceId, channelId: channelId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let dest = dir.appendingPathComponent(tempURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: tempURL, to: dest)
        return dest
    }

    static func fileURL(workspaceId: UUID, channelId: UUID, fileName: String) -> URL {
        baseDirectory(workspaceId: workspaceId, channelId: channelId).appendingPathComponent(fileName)
    }

    private static func baseDirectory(workspaceId: UUID, channelId: UUID) -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return support
            .appendingPathComponent("Publshr/voice-notes", isDirectory: true)
            .appendingPathComponent(workspaceId.uuidString, isDirectory: true)
            .appendingPathComponent(channelId.uuidString, isDirectory: true)
    }
}
