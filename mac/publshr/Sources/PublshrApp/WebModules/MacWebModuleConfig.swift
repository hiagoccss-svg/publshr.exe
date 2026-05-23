import Foundation

/// Configuration injected into embedded web surfaces (whiteboard tldraw, etc.).
struct MacWebModuleConfig: Equatable {
    enum Module: String {
        case whiteboard
    }

    var module: Module
    var spaceId: UUID?
    var whiteboardId: UUID?
    var workspaceId: UUID?
    var accessToken: String?
    var userId: UUID?

    var supabaseURL: String { SupabaseConfig.url.absoluteString }
    var supabaseAnonKey: String { SupabaseConfig.publishableKey }
}
