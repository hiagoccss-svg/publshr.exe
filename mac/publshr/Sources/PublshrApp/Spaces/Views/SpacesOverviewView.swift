import SwiftUI

struct SpacesOverviewView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let space = spaces.selectedSpace {
                    Text(space.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CursorTheme.foreground)
                    if !space.description.isEmpty {
                        Text(space.description)
                            .font(.system(size: 13))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metric("Open tasks", value: spaces.tasks.filter { $0.status != .completed }.count)
                    metric("Completed", value: spaces.tasks.filter { $0.status == .completed }.count)
                    metric("In review", value: spaces.tasks.filter { $0.status == .review }.count)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metric(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("\(value)")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CursorTheme.sideBar.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(CursorTheme.border, lineWidth: 1))
    }
}
