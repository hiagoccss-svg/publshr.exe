import SwiftUI

struct ChatNewProjectSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Binding var isPresented: Bool
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create project").font(.headline)
            Text("Projects group planner work in Chat — same data as the Planner module.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Project name", text: $name)
                .textFieldStyle(.plain)
                .macInlineTextField()
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    Task {
                        await chat.createProject(name: name)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(MacSystemChrome.sheetPadding)
        .frame(width: 380)
        .macNativeSheetPresentation()
    }
}

struct ChatNewPlannerTaskSheet: View {
    @ObservedObject var chat: ChatViewModel
    var projectId: UUID?
    @Binding var isPresented: Bool
    @State private var title = ""

    private var projectName: String? {
        guard let projectId else { return nil }
        return chat.workspaceProjects.first(where: { $0.id == projectId })?.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New task").font(.headline)
            if let projectName {
                Text("In project: \(projectName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField("Task title", text: $title)
                .textFieldStyle(.plain)
                .macInlineTextField()
            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
                Button("Create") {
                    Task {
                        await chat.createPlannerTask(title: title, projectId: projectId)
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(MacSystemChrome.sheetPadding)
        .frame(width: 380)
        .macNativeSheetPresentation()
    }
}
