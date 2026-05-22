import SwiftUI

struct SpacesOverviewView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacesClickUpDesign.overviewSectionSpacing) {
                if let space = spaces.selectedSpace {
                    header(space)
                }

                metricsGrid

                documentsSection

                activitySection
            }
            .padding(SpacesClickUpDesign.overviewPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func header(_ space: SpaceRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(space.name)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(CursorTheme.foreground)
            if !space.description.isEmpty {
                Text(space.description)
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            Text(space.type.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundDim)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CursorTheme.panelBackground)
                .clipShape(Capsule())
        }
    }

    private var metricsGrid: some View {
        let open = spaces.tasks.filter { $0.status != .completed && $0.status != .archived }.count
        let done = spaces.tasks.filter { $0.status == .completed }.count
        let review = spaces.tasks.filter { $0.status == .review }.count
        let urgent = spaces.tasks.filter { $0.priority == .urgent || $0.priority == .high }.count

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard("Open", value: open)
            metricCard("Completed", value: done)
            metricCard("In review", value: review)
            metricCard("High priority", value: urgent)
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Documents")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Spacer()
                HStack(spacing: 6) {
                    TextField("New doc", text: $spaces.newDocumentTitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 120)
                    Button("Add") {
                        Task { await spaces.createDocument(openEditor: true) }
                    }
                    .controlSize(.small)
                    .disabled(spaces.newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if spaces.documents.isEmpty {
                Text("No documents yet — add briefs, notes, or specs for this space.")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
            } else {
                ForEach(spaces.documents.prefix(8)) { doc in
                    Button {
                        spaces.editingDocument = doc
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(CursorTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(CursorTheme.foreground)
                                Text(doc.docType.capitalized)
                                    .font(.system(size: 10))
                                    .foregroundStyle(CursorTheme.foregroundDim)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(CursorTheme.foregroundDim)
                        }
                        .padding(SpacesClickUpDesign.docRowPadding)
                        .background(CursorTheme.panelBackground)
                        .clipShape(RoundedRectangle(cornerRadius: SpacesClickUpDesign.docRowRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)

            if spaces.activity.isEmpty {
                Text("Activity appears when tasks and documents change.")
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundDim)
            } else {
                ForEach(spaces.activity.prefix(12)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        ChatProfileAvatar(
                            profile: spaces.profile(for: item.userId),
                            displayName: spaces.displayName(for: item.userId),
                            size: 28
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spaces.activityLabel(item))
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foreground)
                            Text(item.createdAt, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(CursorTheme.foregroundDim)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func metricCard(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundDim)
            Text("\(value)")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
        }
        .padding(SpacesClickUpDesign.metricCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CursorTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: SpacesClickUpDesign.metricCardRadius))
    }
}
