import Foundation

/// Primary app modules shown in the activity bar (Cursor-style shell).
enum AppModule: String, CaseIterable, Identifiable {
    case chat
    case spaces
    case mediaMonitoring
    case planner
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chat: return "Chat"
        case .spaces: return "Spaces"
        case .mediaMonitoring: return "Media"
        case .planner: return "Planner"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .spaces: return "square.grid.2x2"
        case .mediaMonitoring: return "dot.radiowaves.left.and.right"
        case .planner: return "calendar"
        case .settings: return "gearshape"
        }
    }

    /// All enterprise modules ship inside Publshr.app (no separate Electron windows required).
    static let mainStrip: [AppModule] = [.chat, .spaces, .mediaMonitoring, .planner]

    /// Uses embedded web UI (tldraw / bundled renderer) inside the mac shell.
    var usesEmbeddedWeb: Bool {
        switch self {
        case .mediaMonitoring: return true
        default: return false
        }
    }

    /// Hides the universal Chat/Spaces submenu so the module owns the full width.
    var hidesUniversalSubmenu: Bool {
        switch self {
        case .mediaMonitoring, .planner: return true
        default: return false
        }
    }
}
