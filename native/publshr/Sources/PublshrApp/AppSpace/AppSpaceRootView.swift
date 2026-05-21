import SwiftUI

struct AppSpaceRootView: View {
    @EnvironmentObject private var syncModel: AppModel
    @StateObject private var space = AppSpaceModel()

    var body: some View {
        NavigationSplitView(columnVisibility: $space.columnVisibility) {
            AppSpaceSidebarView()
                .environmentObject(space)
        } detail: {
            HStack(spacing: 0) {
                AppSpaceMainColumn()
                    .environmentObject(space)
                if let taskID = space.selectedTaskID, let task = space.task(by: taskID) {
                    Divider()
                    TaskDetailPanel(task: task)
                        .environmentObject(space)
                        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420)
                }
            }
        }
        .sheet(isPresented: $space.showCreateTask) {
            CreateTaskSheet()
                .environmentObject(space)
        }
        .sheet(isPresented: $space.showCreateList) {
            CreateListSheet()
                .environmentObject(space)
        }
        .sheet(isPresented: $space.showCreateSpace) {
            CreateSpaceSheet()
                .environmentObject(space)
        }
        .sheet(isPresented: $space.showSettings) {
            SettingsSheet()
                .environmentObject(syncModel)
        }
        .frame(minWidth: 1100, minHeight: 680)
        .onReceive(NotificationCenter.default.publisher(for: .publshrNewTask)) { _ in
            space.showCreateTask = true
        }
    }
}
