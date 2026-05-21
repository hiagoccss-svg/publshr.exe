import SwiftUI

struct MainWorkspaceView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            List(selection: $model.selectedDraftID) {
                Section("Library") {
                    ForEach(model.drafts) { draft in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(draft.title)
                                .font(.headline)
                            Text(draft.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(draft.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: model.createDraft) {
                        Image(systemName: "plus")
                    }
                    .help("New draft")
                }
            }
        } detail: {
            VStack(spacing: 0) {
                HStack {
                    Text(model.selectedDraft?.title ?? "Publshr")
                        .font(.title2.bold())
                    Spacer()
                    Button("Publish") { }
                        .buttonStyle(.borderedProminent)
                        .disabled(model.preferOffline)
                    Button("Settings…") { openSettings() }
                }
                .padding()

                Divider()

                TextEditor(text: $model.editorText)
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))

                Divider()

                HStack {
                    Text(model.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("v\(AppVersionLabel.current)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.bar)
            }
        }
        .navigationTitle("Publshr")
        .toolbarTitleDisplayMode(.inline)
    }
}

enum AppVersionLabel {
    static var current: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
