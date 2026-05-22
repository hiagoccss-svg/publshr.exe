import SwiftUI

struct SpacesCalendarView: View {
    @ObservedObject var spaces: SpacesViewModel
    @State private var monthAnchor = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Text(monthTitle)
                    .font(.system(size: 14, weight: .semibold))
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(CursorTheme.foregroundDim)
                }
                ForEach(calendarDays, id: \.self) { day in
                    dayCell(day)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var weekdaySymbols: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthAnchor)
    }

    private var calendarDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let range = cal.range(of: .day, in: .month, for: monthAnchor),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) else { return [] }
        let weekday = cal.component(.weekday, from: start)
        let offset = (weekday + 5) % 7
        var days: [Date] = []
        if offset > 0 {
            for i in stride(from: offset, to: 0, by: -1) {
                if let d = cal.date(byAdding: .day, value: -i, to: start) { days.append(d) }
            }
        }
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: start) { days.append(d) }
        }
        while days.count % 7 != 0 {
            if let last = days.last, let next = cal.date(byAdding: .day, value: 1, to: last) {
                days.append(next)
            } else { break }
        }
        return days
    }

    private func dayCell(_ day: Date) -> some View {
        let tasks = tasks(on: day)
        let inMonth = Calendar.current.isDate(day, equalTo: monthAnchor, toGranularity: .month)
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(inMonth ? CursorTheme.foreground : CursorTheme.foregroundDim)
            ForEach(tasks.prefix(2)) { task in
                Text(task.title)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(CursorTheme.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if tasks.count > 2 {
                Text("+\(tasks.count - 2)")
                    .font(.system(size: 8))
                    .foregroundStyle(CursorTheme.foregroundDim)
            }
        }
        .frame(minHeight: 56, alignment: .topLeading)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(CursorTheme.panelBackground.opacity(inMonth ? 1 : 0.4)))
    }

    private func tasks(on day: Date) -> [SpaceTaskRecord] {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        let key = f.string(from: day)
        return spaces.filteredTasks.filter { $0.dueDate == key }
    }

    private func shiftMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = next
        }
    }
}
