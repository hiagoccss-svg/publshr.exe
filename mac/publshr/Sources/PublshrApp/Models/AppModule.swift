import Foundation

/// Primary app modules shown in the activity bar (Cursor-style shell).
enum AppModule: String, CaseIterable, Identifiable {
    case chat
    case spaces
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chat: return "Chat"
        case .spaces: return "Spaces"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right"
        case .spaces: return "square.grid.2x2"
        case .settings: return "gearshape"
        }
    }

    /// Modules pinned in the main activity strip (settings lives at the bottom).
    static let mainStrip: [AppModule] = [.chat, .spaces]
}
