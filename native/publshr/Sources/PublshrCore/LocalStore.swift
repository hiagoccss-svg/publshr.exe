import Foundation

public enum LocalStore {
    private static var fileURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("workspace.json")
    }

    public static func load() -> WorkspaceData {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(WorkspaceData.self, from: data) else {
            return defaultWorkspace()
        }
        return decoded
    }

    public static func save(_ workspace: WorkspaceData) {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(workspace) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    public static func defaultWorkspace() -> WorkspaceData {
        let marketingID = UUID()
        let productID = UUID()
        let generalID = UUID()
        let designID = UUID()

        return WorkspaceData(
            spaces: [
                OfflineCatalogSpace(
                    id: marketingID,
                    name: "Marketing",
                    colorHex: "7C3AED",
                    folders: [
                        OfflineSpaceFolder(name: "Campaigns", lists: [
                            OfflineSpaceList(name: "Q2 Launch"),
                            OfflineSpaceList(name: "Social"),
                        ]),
                        OfflineSpaceFolder(name: "Assets", lists: [OfflineSpaceList(name: "Brand kit")]),
                    ]
                ),
                OfflineCatalogSpace(
                    id: productID,
                    name: "Product",
                    colorHex: "2563EB",
                    folders: [
                        OfflineSpaceFolder(name: "Roadmap", lists: [
                            OfflineSpaceList(name: "Sprint board"),
                            OfflineSpaceList(name: "Backlog"),
                        ]),
                    ]
                ),
            ],
            channels: [
                OfflineChatChannel(id: generalID, name: "general", spaceID: marketingID),
                OfflineChatChannel(id: designID, name: "design", spaceID: productID),
                OfflineChatChannel(name: "announcements", spaceID: marketingID),
                OfflineChatChannel(name: "Hiago", isDM: true),
            ],
            messages: [
                OfflineChatMessage(channelID: generalID, author: "Team", body: "Welcome to Publshr Chat.", sentAt: .now.addingTimeInterval(-3600)),
                OfflineChatMessage(channelID: generalID, author: "You", body: "Works offline.", sentAt: .now.addingTimeInterval(-1800)),
                OfflineChatMessage(channelID: designID, author: "Design", body: "Spaces and Chat.", sentAt: .now.addingTimeInterval(-900)),
            ]
        )
    }
}
