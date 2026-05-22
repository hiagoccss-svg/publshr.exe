import SwiftUI

/// Enterprise team chat — borderless column wired to the shell sidebars.
struct EnterpriseChatView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @ObservedObject var chat: ChatViewModel
    var topInset: CGFloat = 0
    var embedInPopOut: Bool = false
    @State private var showPlannerShare = false

    var body: some View {
        ChatWorkspaceChrome(topInset: topInset, embedInPopOut: embedInPopOut) {
            ChatConversationView(chat: chat)
        }
        .sheet(isPresented: $chat.showSearchSheet) { ChatSearchSheet(chat: chat) }
        .sheet(isPresented: $chat.showAISheet) { ChatAISheet(chat: chat) }
        .sheet(isPresented: $chat.showPermissionsSheet) { ChatPermissionsSheet(chat: chat) }
        .sheet(isPresented: $showPlannerShare) { plannerShareSheet }
        .onAppear {
            if chat.currentUserId == nil {
                chat.attach(auth: auth)
            }
        }
    }

    private var plannerShareSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share planner item").font(.headline)
            if chat.plannerTasks.isEmpty {
                Text("No tasks in workspace yet.")
                    .foregroundStyle(.secondary)
            } else {
                List(chat.plannerTasks) { task in
                    Button {
                        Task {
                            await chat.sharePlannerTask(task)
                            showPlannerShare = false
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(task.title)
                            Text(task.status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Button("Close") { showPlannerShare = false }
        }
        .padding(20)
        .frame(width: 360, height: 400)
    }
}
