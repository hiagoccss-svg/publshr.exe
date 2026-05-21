import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Publshr")
                        .font(.largeTitle.bold())
                    Text("Version \(AppVersionLabel.current)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            GroupBox("Status") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.statusLine, systemImage: model.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    Text(model.detailText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text("Git commit:")
                            .foregroundStyle(.secondary)
                        Text(model.commitLabel)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Toggle("Work offline only (no Git sync)", isOn: $model.preferOffline)

            HStack {
                Button {
                    Task { await model.checkForUpdates() }
                } label: {
                    if model.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text("Sync from GitHub")
                }
                .disabled(model.isSyncing)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }

            Text("Changes pushed to the repo sync here when online. The app runs without a Terminal window.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
    }
}

enum AppVersionLabel {
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
