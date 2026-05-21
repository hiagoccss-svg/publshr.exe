import SwiftUI
import PublshrCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(model)
                .tabItem { Label("General", systemImage: "gearshape") }

            UpdatesSettingsTab()
                .environmentObject(model)
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
        }
        .frame(width: 420, height: 280)
    }
}

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Toggle("Work offline only", isOn: $model.preferOffline)
            LabeledContent("App location") {
                Text(Bundle.main.bundlePath)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct UpdatesSettingsTab: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Text("Software updates run inside Publshr. When we push to GitHub, sync pulls the latest project copy.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledContent("Branch") {
                Text(AppConfig.defaultBranch)
                    .font(.system(.body, design: .monospaced))
            }

            LabeledContent("Latest commit") {
                Text(model.lastCommit)
                    .font(.system(.body, design: .monospaced))
            }

            if !model.settingsUpdateNote.isEmpty {
                Text(model.settingsUpdateNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Sync now") {
                    Task { await model.syncFromSettings() }
                }
                .disabled(model.isSyncing)

                if model.isSyncing {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
