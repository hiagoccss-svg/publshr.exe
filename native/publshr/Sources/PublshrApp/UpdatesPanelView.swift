import SwiftUI
import PublshrCore

struct UpdatesPanelView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Updates")
                .font(.title2.bold())

            Text("Built into Publshr. When we push to GitHub, tap **Sync now** to pull the latest project files.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GroupBox("Status") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.statusLine, systemImage: model.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                    Text(model.detailText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Text("Latest commit:")
                            .foregroundStyle(.secondary)
                        Text(model.commitLabel)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Toggle("Work offline only", isOn: $model.preferOffline)

            Button {
                Task { await model.syncNow() }
            } label: {
                if model.isSyncing {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }
                Text("Sync now")
            }
            .disabled(model.isSyncing)
            .keyboardShortcut("r", modifiers: .command)

            Text("Branch: \(AppConfig.defaultBranch)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .navigationTitle("Updates")
    }
}
