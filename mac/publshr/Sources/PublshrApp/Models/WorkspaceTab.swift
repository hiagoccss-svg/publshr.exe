import Foundation

/// A document-style tab in the workspace header (apps, channels, DMs, spaces).
enum WorkspaceTabKind: Equatable, Hashable {
    case app(AppModule)
    case chatChannel(UUID)
    case chatDirectMessage(UUID)
    case space(UUID)

    var stableId: String {
        switch self {
        case .app(let module):
            return "app:\(module.rawValue)"
        case .chatChannel(let id):
            return "chat:\(id.uuidString)"
        case .chatDirectMessage(let id):
            return "dm:\(id.uuidString)"
        case .space(let id):
            return "space:\(id.uuidString)"
        }
    }
}

struct WorkspaceTab: Identifiable, Equatable, Hashable {
    let kind: WorkspaceTabKind
    var title: String
    var subtitle: String?
    var iconSystemName: String
    var isPinned: Bool

    var id: String { kind.stableId }

    init(
        kind: WorkspaceTabKind,
        title: String,
        subtitle: String? = nil,
        iconSystemName: String,
        isPinned: Bool = false
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.isPinned = isPinned
    }

    static func app(_ module: AppModule) -> WorkspaceTab {
        WorkspaceTab(
            kind: .app(module),
            title: module.label,
            subtitle: "Application",
            iconSystemName: module.systemImage
        )
    }

    static func chat(_ channel: ChatChannel) -> WorkspaceTab {
        let kind: WorkspaceTabKind = channel.kind == .dm || channel.kind == .group
            ? .chatDirectMessage(channel.id)
            : .chatChannel(channel.id)
        return WorkspaceTab(
            kind: kind,
            title: channel.displayTitle,
            subtitle: channel.kind == .channel ? "Channel" : "Direct message",
            iconSystemName: channel.sidebarIcon
        )
    }

    static func space(_ space: SpaceRecord) -> WorkspaceTab {
        WorkspaceTab(
            kind: .space(space.id),
            title: space.name,
            subtitle: space.workspaceTabTypeLabel,
            iconSystemName: space.workspaceTabIcon,
            isPinned: space.isPinned
        )
    }
}

extension SpaceRecord {
    var workspaceTabTypeLabel: String {
        switch type.lowercased() {
        case "project": return "Project space"
        case "campaign": return "Campaign"
        default: return "Space"
        }
    }

    var workspaceTabIcon: String {
        switch type.lowercased() {
        case "project": return "folder"
        case "campaign": return "megaphone"
        default: return "square.grid.2x2"
        }
    }
}
