import AppKit
import Foundation

/// Persists window frames for main IDE and chat pop-outs across launches.
enum AppWindowStateStore {
    private static let prefix = "com.publshr.app.window."

    static func saveMainWindowFrame(_ frame: NSRect) {
        save(frame, key: "\(prefix)main")
    }

    static func loadMainWindowFrame() -> NSRect? {
        load(key: "\(prefix)main")
    }

    static func saveChatPopOutFrame(channelId: UUID, frame: NSRect) {
        save(frame, key: "\(prefix)chat.\(channelId.uuidString)")
    }

    static func loadChatPopOutFrame(channelId: UUID) -> NSRect? {
        load(key: "\(prefix)chat.\(channelId.uuidString)")
    }

    private static func save(_ frame: NSRect, key: String) {
        let dict: [String: Double] = [
            "x": frame.origin.x,
            "y": frame.origin.y,
            "w": frame.size.width,
            "h": frame.size.height,
        ]
        UserDefaults.standard.set(dict, forKey: key)
    }

    private static func load(key: String) -> NSRect? {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Double],
              let x = dict["x"], let y = dict["y"], let w = dict["w"], let h = dict["h"],
              w >= 320, h >= 400 else {
            return nil
        }
        return NSRect(x: x, y: y, width: w, height: h)
    }
}
