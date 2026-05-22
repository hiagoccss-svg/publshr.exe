import SwiftUI

struct SpacesOverviewView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let space = spaces.selectedSpace {
                    header(space)
                }
                metrics
                approvalsSection
                documentsSection
                filesSection
                activitySection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SpacesNativeDesign.workspaceBackground)
    }

    @ViewBuilder
    private func header(_ space: SpaceRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(space.name)
                .font(.system(size: 22, weight: .semibold))
            if !space.description.isEmpty {
                Text(space.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(space.type.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(Capsule())
        }
    }

    private var metrics: some View {
        let open = spaces.tasks.filter { $0.status != .completed && $0.status != .archived }.count
        let done = spaces.tasks.filter { $0.status == .completed }.count
        let review = spaces.tasks.filter { $0.status == .review }.count
        let pendingApprovals = spaces.approvals.filter { $0.status != "approved" && $0.status != "rejected" }.count

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
            metric("Open tasks", open)
            metric("Completed", done)
            metric("In review", review)
            metric("Approvals", pendingApprovals)
        }
    }

    private var approvalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SpacesNativeDesign.sectionHeader("Approvals")
            if spaces.approvals.isEmpty {
                Text("No approval requests in this space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spaces.approvals.prefix(8)) { item in
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.system(size: 12, weight: .medium))
                            Text(item.statusLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SpacesNativeDesign.sectionHeader("Documents")
                Spacer()
                TextField("Title", text: $spaces.newDocumentTitle)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
                Button("Add") { Task { await spaces.createDocument() } }
                    .controlSize(.small)
                    .disabled(spaces.newDocumentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if spaces.documents.isEmpty {
                Text("Add briefs, specs, and notes for this space.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spaces.documents) { doc in
                    Button {
                        spaces.editingDocument = doc
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(CursorTheme.accent)
                            VStack(alignment: .leading) {
                                Text(doc.title)
                                    .font(.system(size: 12, weight: .medium))
                                Text(doc.docType)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SpacesNativeDesign.sectionHeader("Files")
            if spaces.files.isEmpty {
                Text("Attach files via Supabase Storage (URLs appear here).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spaces.files.prefix(6)) { file in
                    Link(destination: URL(string: file.fileUrl) ?? URL(string: "about:blank")!) {
                        HStack {
                            Image(systemName: "paperclip")
                            Text(file.fileName)
                                .lineLimit(1)
                            Spacer()
                        }
                        .font(.system(size: 12))
                    }
                    .padding(8)
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SpacesNativeDesign.sectionHeader("Activity")
            if spaces.activity.isEmpty {
                Text("Live activity from your team appears here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(spaces.activity.prefix(15)) { item in
                    HStack(alignment: .top, spacing: 10) {
                        ChatProfileAvatar(
                            profile: spaces.profile(for: item.userId),
                            displayName: spaces.displayName(for: item.userId),
                            size: 28
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spaces.activityLabel(item))
                                .font(.system(size: 12))
                            Text(item.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func metric(_ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 24, weight: .medium))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
