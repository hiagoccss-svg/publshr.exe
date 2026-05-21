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
                Space(
                    id: marketingID,
                    name: "Marketing",
                    colorHex: "7C3AED",
                    folders: [
                        SpaceFolder(name: "Campaigns", lists: [
                            SpaceList(name: "Q2 Launch"),
                            SpaceList(name: "Social"),
                        ]),
                        SpaceFolder(name: "Assets", lists: [SpaceList(name: "Brand kit")]),
                    ]
                ),
                Space(
                    id: productID,
                    name: "Product",
                    colorHex: "2563EB",
                    folders: [
                        SpaceFolder(name: "Roadmap", lists: [
                            SpaceList(name: "Sprint board"),
                            SpaceList(name: "Backlog"),
                        ]),
                    ]
                ),
            ],
            channels: [
                ChatChannel(id: generalID, name: "general", spaceID: marketingID),
                ChatChannel(id: designID, name: "design", spaceID: productID),
                ChatChannel(name: "announcements", spaceID: marketingID),
                ChatChannel(name: "Hiago", isDM: true),
            ],
            messages: [
                ChatMessage(channelID: generalID, author: "Team", body: "Welcome to Publshr Chat — ClickUp-style channels inside your Mac app.", sentAt: .now.addingTimeInterval(-3600)),
                ChatMessage(channelID: generalID, author: "You", body: "Works offline. Messages save on this Mac.", sentAt: .now.addingTimeInterval(-1800)),
                ChatMessage(channelID: designID, author: "Design", body: "Spaces and Chat in one Cursor-style layout.", sentAt: .now.addingTimeInterval(-900)),
            ]
        )
    }
}
