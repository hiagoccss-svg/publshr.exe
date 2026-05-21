import SwiftUI
import PublshrCore

/// Cursor-style light layout: Spaces | Context (channels/tasks) | Main
struct AppShellView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            TopToolbarView()
            HStack(spacing: 0) {
                ProjectsColumnView()
                    .frame(width: PublshrTheme.sidebarWidth)
                Divider().overlay(PublshrTheme.border)
                ContextColumnView()
                    .frame(width: PublshrTheme.contextWidth)
                Divider().overlay(PublshrTheme.border)
                MainColumnView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(PublshrTheme.bg)
        .preferredColorScheme(.light)
        .task { await model.bootstrapAfterLogin() }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct ProjectsColumnView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Spaces")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PublshrTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            List(selection: $model.selectedSpaceId) {
                ForEach(model.spaces) { space in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: space.color ?? "3B82F6") ?? PublshrTheme.accent)
                            .frame(width: 8, height: 8)
                        Text(space.name)
                    }
                    .tag(Optional(space.id))
                    .onTapGesture {
                        model.selectedSpaceId = space.id
                        model.mode = .projects
                        Task { await model.loadTasks() }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
        .background(PublshrTheme.sidebar)
    }
}

struct ContextColumnView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.mode == .chat {
                ChatChannelsColumn()
            } else {
                TasksContextColumn()
            }
        }
        .background(PublshrTheme.sidebar)
    }
}

struct ChatChannelsColumn: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Channels")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PublshrTheme.textSecondary)
                .padding(12)
            List(selection: $model.selectedChannelId) {
                ForEach(model.channels) { ch in
                    Text("#\(ch.name)")
                        .tag(Optional(ch.id))
                        .onTapGesture {
                            model.selectedChannelId = ch.id
                            Task { await model.loadMessages() }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

struct TasksContextColumn: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tasks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PublshrTheme.textSecondary)
                .padding(12)
            List {
                ForEach(model.tasks) { task in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title).font(.subheadline.weight(.medium))
                        Text(task.status ?? "open")
                            .font(.caption2)
                            .foregroundStyle(PublshrTheme.textSecondary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

struct MainColumnView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if model.mode == .chat {
                ChatMainPanel()
            } else {
                ProjectsMainPanel()
            }
        }
        .background(PublshrTheme.panel)
    }
}

struct ChatMainPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            if let ch = model.channels.first(where: { $0.id == model.selectedChannelId }) {
                Text("#\(ch.name)")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(model.messages) { msg in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(msg.createdAt ?? .now, style: .time)
                                .font(.caption2)
                                .foregroundStyle(PublshrTheme.textSecondary)
                            Text(msg.body)
                                .textSelection(.enabled)
                        }
                        .padding(10)
                        .background(PublshrTheme.sidebar)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            Divider()
            HStack {
                TextField("Message…", text: $model.chatInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button("Send") { Task { await model.sendMessage() } }
                    .buttonStyle(.borderedProminent)
                    .tint(PublshrTheme.accent)
            }
            .padding(12)
        }
    }
}

struct ProjectsMainPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.spaces.first(where: { $0.id == model.selectedSpaceId })?.name ?? "Project")
                .font(.title.bold())
            Text("ClickUp-style tasks backed by Supabase on your desktop.")
                .foregroundStyle(PublshrTheme.textSecondary)
            if model.tasks.isEmpty {
                Text("No tasks — click **Task** in the top bar.")
                    .foregroundStyle(PublshrTheme.textSecondary)
            } else {
                ForEach(model.tasks) { task in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(PublshrTheme.accent)
                        Text(task.title)
                        Spacer()
                        Text(task.status ?? "open")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(PublshrTheme.sidebar)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 6)
                }
            }
            Spacer()
        }
        .padding(24)
    }
}

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if s.count == 6 { s = "FF" + s }
        guard let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}
