import SwiftUI

/// Shown when the workspace plan does not include a module.
struct EnterpriseModuleGate: View {
    let moduleName: String
    let planName: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("\(moduleName) is not on your plan")
                .font(.headline)
            Text("Your workspace is on the \(planName) plan. Ask an administrator to upgrade in Settings → Subscription.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Open Settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: SettingsSection.billing.rawValue)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CursorTheme.editorBackground)
    }
}

extension Notification.Name {
    static let publshrOpenSettings = Notification.Name("com.publshr.openSettings")
}
