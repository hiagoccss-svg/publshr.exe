import SwiftUI

/// ClickUp Timeline / Gantt — matches `desktop/spaces/.../TimelineView.tsx`.
struct SpacesTimelineView: View {
    @ObservedObject var spaces: SpacesViewModel
    @State private var anchorWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()

    private let dayWidth: CGFloat = 28
    private let rowHeight: CGFloat = 36
    private let weekCount = 6

    var body: some View {
        let rangeStart = startOfWeek(anchorWeek)
        let rangeEnd = Calendar.current.date(byAdding: .day, value: weekCount * 7, to: rangeStart) ?? rangeStart
        let totalDays = max(1, Calendar.current.dateComponents([.day], from: rangeStart, to: rangeEnd).day ?? 42) + 1
        let scheduled = scheduledTasks(rangeStart: rangeStart, rangeEnd: rangeEnd, totalDays: totalDays)
        let unscheduled = spaces.filteredTasks.filter { task in
            task.status != .archived && taskSpan(task, rangeStart: rangeStart, rangeEnd: rangeEnd) == nil
        }

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { shiftAnchor(weeks: -2) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Text("\(formatShort(rangeStart)) – \(formatLong(rangeEnd))")
                    .font(.system(size: 12, weight: .medium))
                Button { shiftAnchor(weeks: 2) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Set start/due dates in task details to schedule")
                    .font(.system(size: 10))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CursorTheme.panelBackground.opacity(0.5))

            ScrollView([.horizontal, .vertical]) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Task")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                            .frame(width: 192, height: 32, alignment: .leading)
                            .padding(.leading, 8)
                        ForEach(scheduled) { item in
                            Text(item.task.title)
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .frame(width: 192, height: rowHeight, alignment: .leading)
                                .padding(.leading, 8)
                        }
                    }
                    .background(CursorTheme.editorBackground)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            ForEach(0..<totalDays, id: \.self) { offset in
                                let day = Calendar.current.date(byAdding: .day, value: offset, to: rangeStart) ?? rangeStart
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.system(size: 9))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                                    .frame(width: dayWidth, height: 32)
                            }
                        }
                        ForEach(scheduled) { item in
                            ZStack(alignment: .leading) {
                                Color.clear.frame(height: rowHeight)
                                Button {
                                    Task { await spaces.selectTask(item.task.id) }
                                } label: {
                                    Text(item.task.title)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 6)
                                        .frame(
                                            width: max(item.span.width, 48),
                                            height: 20,
                                            alignment: .leading
                                        )
                                        .background(barColor(for: item.task))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .offset(x: item.span.left)
                            }
                            .frame(width: CGFloat(totalDays) * dayWidth, height: rowHeight)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !unscheduled.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unscheduled (\(unscheduled.count))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(unscheduled.prefix(12)) { task in
                                Button(task.title) {
                                    Task { await spaces.selectTask(task.id) }
                                }
                                .font(.system(size: 10))
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CursorTheme.panelBackground.opacity(0.35))
            }
        }
        .background(CursorMacShellDesign.editorColumnBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(CursorTheme.borderSubtle))
    }

    private struct ScheduledRow: Identifiable {
        let task: SpaceTaskRecord
        let span: (left: CGFloat, width: CGFloat)
        var id: UUID { task.id }
    }

    private func scheduledTasks(rangeStart: Date, rangeEnd: Date, totalDays: Int) -> [ScheduledRow] {
        spaces.filteredTasks
            .filter { $0.status != .archived }
            .compactMap { task -> ScheduledRow? in
                guard let span = taskSpan(task, rangeStart: rangeStart, rangeEnd: rangeEnd) else { return nil }
                return ScheduledRow(task: task, span: span)
            }
    }

    private func taskSpan(
        _ task: SpaceTaskRecord,
        rangeStart: Date,
        rangeEnd: Date
    ) -> (left: CGFloat, width: CGFloat)? {
        guard let start = parseTaskDate(task.startDate) ?? parseTaskDate(task.dueDate) else { return nil }
        let end = parseTaskDate(task.dueDate) ?? start
        let barStart = max(start, rangeStart)
        let barEnd = min(end, rangeEnd)
        if barEnd < rangeStart || barStart > rangeEnd { return nil }
        let leftDays = Calendar.current.dateComponents([.day], from: rangeStart, to: barStart).day ?? 0
        let widthDays = (Calendar.current.dateComponents([.day], from: barStart, to: barEnd).day ?? 0) + 1
        return (CGFloat(leftDays) * dayWidth, CGFloat(widthDays) * dayWidth)
    }

    private func parseTaskDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let prefix = String(raw.prefix(10))
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.date(from: prefix)
    }

    private func startOfWeek(_ date: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    private func shiftAnchor(weeks: Int) {
        anchorWeek = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: anchorWeek) ?? anchorWeek
    }

    private func formatShort(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }

    private func formatLong(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: d)
    }

    private func barColor(for task: SpaceTaskRecord) -> Color {
        switch task.priority {
        case .urgent: return .red
        case .high: return .orange
        default: return CursorTheme.accent
        }
    }
}
