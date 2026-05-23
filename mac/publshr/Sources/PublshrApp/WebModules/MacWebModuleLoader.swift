import Foundation

enum MacWebModuleLoader {
    /// Bundled `WebBundles/{module}/index.html` copied into `Publshr.app/Contents/Resources/`.
    static func bundleURL(module: MacWebModuleConfig.Module) -> URL? {
        Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebBundles/\(module.rawValue)")
    }

    static func whiteboardPageURL(config: MacWebModuleConfig) -> URL? {
        guard var base = bundleURL(module: .whiteboard) else { return nil }
        var parts = URLComponents(url: base, resolvingAgainstBaseURL: false)
        var query: [URLQueryItem] = []
        if let spaceId = config.spaceId {
            query.append(URLQueryItem(name: "spaceId", value: spaceId.uuidString))
        }
        if let boardId = config.whiteboardId {
            query.append(URLQueryItem(name: "whiteboardId", value: boardId.uuidString))
        }
        if let workspaceId = config.workspaceId {
            query.append(URLQueryItem(name: "workspaceId", value: workspaceId.uuidString))
        }
        parts?.queryItems = query.isEmpty ? nil : query
        return parts?.url ?? base
    }
}
