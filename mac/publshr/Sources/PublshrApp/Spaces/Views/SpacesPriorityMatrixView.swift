import SwiftUI

/// Eisenhower matrix — matches `desktop/spaces/.../PriorityMatrixView.tsx`.
struct SpacesPriorityMatrixView: View {
    @ObservedObject var spaces: SpacesViewModel

    private let quadrants: [(id: String, title: String, subtitle: String)] = [
        ("do", "Do first", "Urgent · due soon"),
        ("schedule", "Schedule", "Important · not urgent"),
        ("delegate", "Delegate", "Urgent · lower priority"),
        ("later", "Later", "Low urgency")
    ]

    var body: some View {
        let open = spaces.filteredTasks.filter { $0.status != .completed && $0.status != .archived }
        let now = Date()
        let soonEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let buckets = bucketTasks(open, now: now, soonEnd: soonEnd)

        GeometryReader { geo in
            let cellW = (geo.size.width - 12) / 2
            let cellH = (geo.size.height - 12) / 2
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quadrantCell(quadrants[0], tasks: buckets["do"] ?? [], width: cellW, height: cellH)
                    quadrantCell(quadrants[1], tasks: buckets["schedule"] ?? [], width: cellW, height: cellH)
                }
                HStack(spacing: 12) {
                    quadrantCell(quadrants[2], tasks: buckets["delegate"] ?? [], width: cellW, height: cellH)
                    quadrantCell(quadrants[3], tasks: buckets["later"] ?? [], width: cellW, height: cellH)
                }
            }
        }
        .frame(minHeight: 360)
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    private func quadrantCell(
        _ q: (id: String, title: String, subtitle: String),
        tasks: [SpaceTaskRecord],
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(q.title)
                    .font(.system(size: 12, weight: .semibold))
                Text(q.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle().fill(CursorTheme.borderSubtle.opacity(0.5)).frame(height: 1)
            }

            ScrollView {
                VStack(spacing: 4) {
                    if tasks.isEmpty {
                        Text("Empty")
                            .font(.system(size: 10))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(tasks) { task in
                            Button {
                                Task { await spaces.selectTask(task.id) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(CursorTheme.foreground)
                                    if let due = task.dueDate, !due.isEmpty {
                                        Text("Due \(String(due.prefix(10)))")
                                            .font(.system(size: 10))
                                            .foregroundStyle(CursorTheme.foregroundMuted)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(CursorTheme.editorBackground.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(8)
            }
        }
        .frame(width: width, height: height)
        .background(CursorTheme.panelBackground.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CursorTheme.borderSubtle))
    }

    private func bucketTasks(
        _ tasks: [SpaceTaskRecord],
        now: Date,
        soonEnd: Date
    ) -> [String: [SpaceTaskRecord]] {
        var buckets: [String: [SpaceTaskRecord]] = [
            "do": [], "schedule": [], "delegate": [], "later": []
        ]
        for task in tasks {
            buckets[classify(task, now: now, soonEnd: soonEnd), default: []].append(task)
        }
        return buckets
    }

    private func classify(_ task: SpaceTaskRecord, now: Date, soonEnd: Date) -> String {
        let urgent = task.priority == .urgent || task.priority == .high
        let due = parseDate(task.dueDate)
        let dueSoon = due.map { $0 <= now || ($0 >= now && $0 <= soonEnd) } ?? false
        if urgent && dueSoon { return "do" }
        if urgent { return "delegate" }
        if dueSoon || task.priority == .normal { return "schedule" }
        return "later"
    }

    private func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: String(raw.prefix(10)))
    }
}
