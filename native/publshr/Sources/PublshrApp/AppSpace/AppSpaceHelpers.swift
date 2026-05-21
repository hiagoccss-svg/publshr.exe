import SwiftUI
import PublshrCore

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 { hex = "FF" + hex }
        guard hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
        let r = Double((value >> 24) & 0xFF) / 255
        let g = Double((value >> 16) & 0xFF) / 255
        let b = Double((value >> 8) & 0xFF) / 255
        let a = Double(value & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        if priority == .none {
            EmptyView()
        } else {
            Text(priority.label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(backgroundColor.opacity(0.2))
                .foregroundStyle(backgroundColor)
                .clipShape(Capsule())
        }
    }

    private var backgroundColor: Color {
        switch priority {
        case .none: return .secondary
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct StatusDot: View {
    let colorHex: String

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex) ?? .secondary)
            .frame(width: 8, height: 8)
    }
}

struct AssigneeAvatars: View {
    let memberIDs: [UserID]
    @EnvironmentObject private var space: AppSpaceModel

    var body: some View {
        HStack(spacing: -6) {
            ForEach(memberIDs.prefix(3), id: \.raw) { id in
                if let member = space.member(for: id) {
                    Circle()
                        .fill(Color(hex: member.colorHex) ?? .accentColor)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                }
            }
        }
    }
}

struct DueDateLabel: View {
    let date: Date?

    var body: some View {
        if let date {
            Text(date, style: .date)
                .font(.caption)
                .foregroundStyle(isOverdue ? .red : .secondary)
        }
    }

    private var isOverdue: Bool {
        guard let date else { return false }
        return date < Calendar.current.startOfDay(for: Date())
    }
}
