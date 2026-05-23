import SwiftUI

/// ClickUp Workload — matches `desktop/spaces/.../WorkloadView.tsx`.
struct SpacesWorkloadView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        let columns = workloadColumns
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(columns, id: \.id) { col in
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: col.colorHex) ?? CursorTheme.accent)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Text(String(col.name.prefix(1)).uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.name)
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(col.tasks.count) task\(col.tasks.count == 1 ? "" : "s")\(col.tasks.count > 8 ? " · heavy load" : "")")
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
                        }

                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(col.tasks) { task in
                                    Button {
                                        Task { await spaces.selectTask(task.id) }
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.title)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(CursorTheme.foreground)
                                                .lineLimit(2)
                                            HStack(spacing: 4) {
                                                Text(task.status.label)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                                if task.priority != .none {
                                                    Text(task.priority.label)
                                                        .font(.system(size: 10))
                                                        .foregroundStyle(CursorTheme.foregroundMuted)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(CursorTheme.editorBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(CursorTheme.borderSubtle.opacity(0.6))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8)
                        }
                    }
                    .frame(width: 256)
                    .background(CursorTheme.panelBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(CursorTheme.borderSubtle))
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    private struct WorkloadColumn: Identifiable {
        let id: String
        let name: String
        let colorHex: String
        let tasks: [SpaceTaskRecord]
    }

    private var workloadColumns: [WorkloadColumn] {
        let open = spaces.filteredTasks.filter { $0.status != .completed && $0.status != .archived }
        var byUser: [UUID: [SpaceTaskRecord]] = [:]
        var unassigned: [SpaceTaskRecord] = []
        for task in open {
            if let aid = task.assigneeId {
                byUser[aid, default: []].append(task)
            } else {
                unassigned.append(task)
            }
        }
        var cols = spaces.profiles
            .sorted { $0.key.uuidString < $1.key.uuidString }
            .map { id, profile in
                WorkloadColumn(
                    id: id.uuidString,
                    name: profile.displayName ?? profile.email,
                    colorHex: "#3d5a80",
                    tasks: byUser[id] ?? []
                )
            }
        if !unassigned.isEmpty {
            cols.append(WorkloadColumn(id: "_none", name: "Unassigned", colorHex: "#94a3b8", tasks: unassigned))
        }
        return cols
    }
}

private extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if s.count == 6 { s = "FF" + s }
        guard s.count == 8, let v = UInt64(s, radix: 16) else { return nil }
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xff) / 255,
            green: Double((v >> 8) & 0xff) / 255,
            blue: Double(v & 0xff) / 255,
            opacity: Double((v >> 24) & 0xff) / 255
        )
    }
}
