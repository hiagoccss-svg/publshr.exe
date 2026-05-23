import Foundation

/// Primary app modules shown in the activity bar (Cursor-style shell).
enum AppModule: String, CaseIterable, Identifiable {
    case chat
    case spaces
    case whiteboard
    case mediaMonitoring
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chat: return "Chat"
        case .spaces: return "Spaces"
        case .whiteboard: return "White Board"
        case .mediaMonitoring: return "Media Monitoring"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .spaces: return "square.grid.2x2"
        case .whiteboard: return "scribble.variable"
        case .mediaMonitoring: return "dot.radiowaves.left.and.right"
        case .settings: return "gearshape"
        }
    }

    /// Uses the Spaces submenu column (search + space tree).
    var usesSpacesSubmenu: Bool {
        switch self {
        case .spaces, .whiteboard: return true
        case .chat, .mediaMonitoring, .settings: return false
        }
    }

    /// Modules pinned in the activity strip. Full settings open from the submenu gear or ⌘,.
    static let mainStrip: [AppModule] = [.chat, .spaces, .whiteboard, .mediaMonitoring]
}
