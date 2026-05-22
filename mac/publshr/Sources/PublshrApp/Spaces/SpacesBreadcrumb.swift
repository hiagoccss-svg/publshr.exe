import Foundation

enum SpacesBreadcrumbKind {
    case space
    case folder
    case list
}

struct SpacesBreadcrumbItem: Identifiable {
    let kind: SpacesBreadcrumbKind
    let title: String
    let spaceId: UUID?
    let folderId: UUID?
    let listId: UUID?
    let isLast: Bool

    var id: String {
        switch kind {
        case .space: return "space:\(spaceId?.uuidString ?? "")"
        case .folder: return "folder:\(folderId?.uuidString ?? "")"
        case .list: return "list:\(listId?.uuidString ?? "")"
        }
    }

    var icon: String? {
        switch kind {
        case .space: return "square.grid.2x2"
        case .folder: return "folder"
        case .list: return "list.bullet"
        }
    }
}
