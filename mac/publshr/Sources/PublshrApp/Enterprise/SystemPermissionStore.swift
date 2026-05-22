import AVFoundation
import Foundation
import UserNotifications

/// macOS TCC prompts — ask once per permission kind, persist in UserDefaults (survives app updates).
@MainActor
enum SystemPermissionStore {
    private static let microphonePromptedKey = "com.publshr.permissions.microphonePrompted"
    private static let cameraPromptedKey = "com.publshr.permissions.cameraPrompted"
    private static let notificationsPromptedKey = "com.publshr.permissions.notificationsPrompted"

    // Legacy chat keys — read once so existing installs are not re-prompted.
    private static let legacyMicKey = "publshr.chat.microphonePrompted"
    private static let legacyNotificationsKey = "publshr.chat.notificationsPrompted"

    static func migrateLegacyPromptFlagsIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: legacyMicKey), !defaults.bool(forKey: microphonePromptedKey) {
            defaults.set(true, forKey: microphonePromptedKey)
        }
        if defaults.bool(forKey: legacyNotificationsKey), !defaults.bool(forKey: notificationsPromptedKey) {
            defaults.set(true, forKey: notificationsPromptedKey)
        }
    }

    static var isMicrophoneDenied: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .denied
            || AVCaptureDevice.authorizationStatus(for: .audio) == .restricted
    }

    static var isCameraDenied: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .denied
            || AVCaptureDevice.authorizationStatus(for: .video) == .restricted
    }

    /// Microphone for voice notes and calls.
    static func ensureMicrophoneAccess() async -> Bool {
        migrateLegacyPromptFlagsIfNeeded()
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            if UserDefaults.standard.bool(forKey: microphonePromptedKey) {
                return false
            }
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            UserDefaults.standard.set(true, forKey: microphonePromptedKey)
            UserDefaults.standard.set(true, forKey: legacyMicKey)
            return granted
        @unknown default:
            return false
        }
    }

    /// Camera for video calls.
    static func ensureCameraAccess() async -> Bool {
        migrateLegacyPromptFlagsIfNeeded()
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            if UserDefaults.standard.bool(forKey: cameraPromptedKey) {
                return false
            }
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            UserDefaults.standard.set(true, forKey: cameraPromptedKey)
            return granted
        @unknown default:
            return false
        }
    }

    /// Microphone + optional camera — used when starting, joining, or accepting a call.
    static func ensureMediaAccessForCall(video: Bool) async -> Bool {
        guard await ensureMicrophoneAccess() else { return false }
        if video {
            return await ensureCameraAccess()
        }
        return true
    }

    /// Notification Center — one prompt per install.
    static func ensureNotificationAccess() async {
        migrateLegacyPromptFlagsIfNeeded()
        guard !UserDefaults.standard.bool(forKey: notificationsPromptedKey) else { return }
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            UserDefaults.standard.set(true, forKey: notificationsPromptedKey)
            UserDefaults.standard.set(true, forKey: legacyNotificationsKey)
            return
        }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        UserDefaults.standard.set(true, forKey: notificationsPromptedKey)
        UserDefaults.standard.set(true, forKey: legacyNotificationsKey)
    }
}
