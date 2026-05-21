import SwiftUI
import PublshrCore

struct CreateTaskSheet: View {
    @EnvironmentObject private var space: AppSpaceModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        Form {
            TextField("Task name", text: $name)
            if let listID = space.activeListID ?? space.document.lists.first?.id {
                Text("List: \(space.document.lists.first { $0.id == listID }?.name ?? "")")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 160)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if let listID = space.activeListID {
                        space.createTask(name: trimmed, listID: listID)
                    } else if let first = space.inboxTasks().first?.listID {
                        space.createTask(name: trimmed, listID: first)
                    } else if let listID = space.document.lists.first?.id {
                        space.createTask(name: trimmed, listID: listID)
                    }
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct CreateListSheet: View {
    @EnvironmentObject private var space: AppSpaceModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var spaceID: SpaceID?

    var body: some View {
        Form {
            TextField("List name", text: $name)
            Picker("Space", selection: $spaceID) {
                ForEach(space.document.spaces.sorted { $0.order < $1.order }) { sp in
                    Text(sp.name).tag(Optional(sp.id))
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
        .onAppear { spaceID = space.document.spaces.first?.id }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    guard let sid = spaceID else { return }
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    space.createList(name: trimmed, spaceID: sid)
                    dismiss()
                }
            }
        }
    }
}

struct CreateSpaceSheet: View {
    @EnvironmentObject private var space: AppSpaceModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        Form {
            TextField("Space name", text: $name)
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 120)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    space.createSpace(name: trimmed)
                    dismiss()
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentView()
            .environmentObject(model)
            .frame(width: 520, height: 420)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
    }
}
