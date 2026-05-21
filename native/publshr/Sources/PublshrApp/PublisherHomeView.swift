import SwiftUI

struct PublisherHomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Publshr")
                        .font(.largeTitle.bold())
                    Text("Publisher · v\(AppVersionLabel.current)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            GroupBox("Installation") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        model.isInstalledInApplications ? "Installed in Applications" : "Running from build folder",
                        systemImage: model.isInstalledInApplications ? "checkmark.seal.fill" : "exclamationmark.triangle"
                    )
                    .foregroundStyle(model.isInstalledInApplications ? Color.primary : Color.orange)

                    Text(model.installPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    if !model.isInstalledInApplications {
                        Text("To install in Applications, run ./install-mac-app.sh from the repo in Terminal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Publisher") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cross-platform publishing helper (macOS app). Works offline.")
                        .foregroundStyle(.secondary)
                    Text("Use the sidebar **Updates** section to sync project changes from GitHub — updates are built into this app, not a separate tool.")
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Check for updates") {
                    Task { await model.checkForUpdatesNow() }
                }
                .keyboardShortcut("u", modifiers: .command)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(24)
        .navigationTitle("Publisher")
        .onAppear { model.refreshInstallStatus() }
    }
}
