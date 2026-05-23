import SwiftUI

struct SpacesNewSpaceSheet: View {
    @ObservedObject var spaces: SpacesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New Space")
                .font(.title2.weight(.semibold))
                .padding(.bottom, 16)

            Form {
                TextField("Name", text: $spaces.newSpaceName)
                Picker("Type", selection: $spaces.newSpaceType) {
                    ForEach(SpaceTypeOption.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                Text("Use folders inside the Space for project groupings (ClickUp-style).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Description (optional)", text: $spaces.newSpaceDescription, axis: .vertical)
                    .lineLimit(2...4)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") {
                    spaces.showNewSpaceSheet = false
                    dismiss()
                }
                Button("Create Space") {
                    Task { await spaces.createSpace() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(spaces.newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 16)
        }
        .padding(24)
        .frame(width: 420)
    }
}
