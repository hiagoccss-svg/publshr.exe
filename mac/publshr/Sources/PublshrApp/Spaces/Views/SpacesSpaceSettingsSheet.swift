import SwiftUI

/// Space settings — matches `desktop/spaces/.../SpaceSettingsModal.tsx`.
struct SpacesSpaceSettingsSheet: View {
    @ObservedObject var spaces: SpacesViewModel
    let spaceId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var defaultView: SpacesViewModel.TaskViewMode = .overview
    @State private var busy = false

    private var space: SpaceRecord? {
        spaces.spaces.first { $0.id == spaceId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Space settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()

            if let space {
                Form {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Default view", selection: $defaultView) {
                        ForEach(SpacesViewModes.tabOrder.filter { $0 != .whiteboard }) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    Toggle("Pinned", isOn: Binding(
                        get: { space.isPinned },
                        set: { v in Task { await spaces.updateSpaceMetadata(id: spaceId, name: nil, description: nil, isPinned: v) } }
                    ))

                    Toggle("Favorite", isOn: Binding(
                        get: { space.isFavourite },
                        set: { v in Task { await spaces.updateSpaceMetadata(id: spaceId, name: nil, description: nil, isFavourite: v) } }
                    ))
                }
                .formStyle(.grouped)
                .onAppear {
                    name = space.name
                    description = space.description
                    defaultView = spaces.defaultView(for: spaceId)
                }

                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.cancelAction)
                    Button("Save") {
                        Task { await save(space) }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(busy || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .frame(width: 440, minHeight: 360)
    }

    private func save(_ space: SpaceRecord) async {
        busy = true
        defer { busy = false }
        await spaces.updateSpaceMetadata(
            id: space.id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        spaces.setDefaultView(for: space.id, view: defaultView)
        dismiss()
    }
}
