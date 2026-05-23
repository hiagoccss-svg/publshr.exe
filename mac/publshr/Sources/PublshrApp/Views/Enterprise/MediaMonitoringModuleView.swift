import SwiftUI

/// In-IDE entry for the Media Monitoring desktop companion.
struct MediaMonitoringModuleView: View {
    @State private var launchMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("Media Monitoring")
                .font(.system(size: 18, weight: .semibold))
            Text("Coverage feeds, sentiment, and clipping detail run in the dedicated desktop app.")
                .font(.system(size: 13))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            if let launchMessage {
                Text(launchMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            HStack(spacing: 10) {
                Button("Open Media Monitoring") {
                    openCompanion()
                }
                .buttonStyle(.borderedProminent)
                Button("Copy install command") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        "cd desktop/media-monitoring && npm install && npm run dev",
                        forType: .string
                    )
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .onAppear { openCompanionIfInstalled() }
    }

    private func openCompanionIfInstalled() {
        if DesktopCompanionAppLauncher.open(.mediaMonitoring) {
            launchMessage = nil
        }
    }

    private func openCompanion() {
        if DesktopCompanionAppLauncher.open(.mediaMonitoring) {
            launchMessage = nil
        } else {
            launchMessage = DesktopCompanionAppLauncher.installHint(for: .mediaMonitoring)
        }
    }
}
