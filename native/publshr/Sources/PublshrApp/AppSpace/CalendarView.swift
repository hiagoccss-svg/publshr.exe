import SwiftUI
import PublshrCore

struct CalendarView: View {
    let list: TaskList
    @EnvironmentObject private var space: AppSpaceModel
    @State private var monthAnchor = Date()

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: 0) {
            monthHeader
            Divider()
            weekdayHeader
            Divider()
            daysGrid
        }
        .padding(8)
    }

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Text(monthAnchor, format: .dateTime.month(.wide).year())
                .font(.headline)
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
            Spacer()
            Button("Today") { monthAnchor = Date() }
                .buttonStyle(.bordered)
        }
        .padding(12)
    }

    private var weekdayHeader: some View {
        let symbols = calendar.shortWeekdaySymbols
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }

    private var daysGrid: some View {
        let days = daysInMonth()
        let tasks = space.tasks(for: list.id)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
            ForEach(days, id: \.self) { day in
                dayCell(day: day, tasks: tasks(on: day, from: tasks))
            }
        }
    }

    private func dayCell(day: Date?, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let day {
                Text("\(calendar.component(.day, from: day))")
                    .font(.caption.weight(calendar.isDateInToday(day) ? .bold : .regular))
                    .foregroundStyle(calendar.isDateInToday(day) ? Color.accentColor : .primary)
                ForEach(tasks.prefix(3), id: \.id.raw) { task in
                    Text(task.name)
                        .font(.caption2)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .onTapGesture { space.selectTask(task.id) }
                }
                if tasks.count > 3 {
                    Text("+\(tasks.count - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 88, alignment: .topLeading)
        .padding(6)
        .background(day == nil ? Color.clear : Color(nsColor: .controlBackgroundColor).opacity(0.3))
        .overlay(Rectangle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
    }

    private func tasks(on day: Date, from all: [TaskItem]) -> [TaskItem] {
        all.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: day)
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: interval.start) else { return [] }
        var days: [Date?] = []
        var current = firstWeek.start
        while current < interval.end || days.count % 7 != 0 {
            if current < interval.start || current >= interval.end {
                days.append(nil)
            } else {
                days.append(current)
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
            if days.count > 42 { break }
        }
        return days
    }

    private func shiftMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }
}
