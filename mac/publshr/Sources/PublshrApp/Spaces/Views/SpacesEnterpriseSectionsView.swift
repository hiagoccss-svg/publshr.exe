import SwiftUI

/// Operations content (Dashboard, Documents, …) — live Supabase data, same sections as Electron Spaces.
struct SpacesEnterpriseSectionsView: View {
    @ObservedObject var spaces: SpacesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch spaces.activeSection {
                case .dashboard:
                    reportsSection
                case .documents: documentsSection
                case .whiteboard:
                    if spaces.selectedSpace != nil {
                        SpacesWhiteboardView(spaces: spaces)
                    } else {
                        whiteboardPickSpacePrompt
                    }
                case .approvals: approvalsSection
                case .reports: reportsSection
                case .clients: spacesByTypeSection(type: "client", title: "Clients")
                case .campaigns: spacesByTypeSection(type: "campaign", title: "Campaigns")
                case .team: teamSection
                case .files: filesSection
                case .planner: plannerSection
                case .chat: chatSection
                case .media: mediaSection
                case .settings: settingsSection
                case .spaces: EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(CursorMacShellDesign.editorColumnBackground)
    }

    private var whiteboardPickSpacePrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Whiteboard", subtitle: "Pick a space in the submenu to open its canvas.")
            if let first = spaces.spaces.first {
                Button("Open \(first.name)") {
                    Task { await spaces.selectSpace(first.id) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Sections

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Documents", subtitle: "Briefs and specs across all spaces (live from Supabase).")
            if spaces.workspaceDocuments.isEmpty {
                emptyHint("No documents yet. Create one inside a space.")
            } else {
                ForEach(spaces.workspaceDocuments) { doc in
                    Button {
                        Task {
                            await spaces.selectSpace(doc.spaceId)
                            spaces.editingDocument = doc
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title).font(.system(size: 13, weight: .medium))
                                Text(spaces.spaceName(for: doc.spaceId))
                                    .font(.system(size: 11))
                                    .foregroundStyle(CursorTheme.foregroundMuted)
                            }
                            Spacer()
                            Text(doc.updatedAt, style: .date)
                                .font(.system(size: 10))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }
                        .padding(10)
                        .background(LibraryGlassDesign.cardGlassFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var approvalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Approvals", subtitle: "Document, task, and campaign approval requests.")
            if spaces.workspaceApprovals.isEmpty {
                emptyHint("No approval requests.")
            } else {
                ForEach(spaces.workspaceApprovals) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.system(size: 13, weight: .medium))
                            Text(spaces.spaceName(for: item.spaceId))
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }
                        Spacer()
                        Text(item.status.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(item.isPending ? CursorTheme.accent : CursorTheme.foregroundMuted)
                    }
                    .padding(10)
                    .background(LibraryGlassDesign.cardGlassFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Reports", subtitle: "Operational metrics from your workspace.")
            if let s = spaces.workspaceSummary {
                panel("Summary") {
                    reportRow("Spaces", "\(s.spaceCount)")
                    reportRow("Open tasks", "\(s.openTasks)")
                    reportRow("Documents", "\(s.documentCount)")
                    reportRow("Pending approvals", "\(s.pendingApprovals)")
                }
            }
            let grouped = Dictionary(grouping: spaces.workspaceTasks, by: \.status)
            panel("Tasks by status") {
                if grouped.isEmpty {
                    emptyHint("No task data.")
                } else {
                    ForEach(SpaceTaskStatus.allCases.filter { grouped[$0] != nil }) { status in
                        reportRow(status.label, "\(grouped[status]?.count ?? 0)")
                    }
                }
            }
        }
    }

    private func spacesByTypeSection(type: String, title: String) -> some View {
        let items = spaces.spacesFiltered(type: type)
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title, subtitle: "\(title) spaces in this workspace.")
            if items.isEmpty {
                emptyHint("No \(title.lowercased()) spaces yet.")
            } else {
                ForEach(items) { space in
                    Button {
                        Task { await spaces.selectSpace(space.id) }
                    } label: {
                        HStack {
                            Circle().fill(SpaceColor.hex(space.color)).frame(width: 8, height: 8)
                            Text(space.name).font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        .padding(10)
                        .background(LibraryGlassDesign.cardGlassFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Team", subtitle: "Workspace members.")
            if spaces.profiles.isEmpty {
                emptyHint("No team members loaded.")
            } else {
                ForEach(Array(spaces.profiles.values).sorted { ($0.displayName ?? $0.email) < ($1.displayName ?? $1.email) }) { profile in
                    HStack(spacing: 10) {
                        Text(String((profile.displayName ?? profile.email).prefix(1)).uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(CursorTheme.accent)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.displayName ?? profile.email)
                                .font(.system(size: 13, weight: .medium))
                            Text(profile.email)
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(LibraryGlassDesign.cardGlassFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Files", subtitle: "Attachments linked to spaces.")
            if spaces.workspaceFiles.isEmpty {
                emptyHint("No files yet.")
            } else {
                ForEach(spaces.workspaceFiles) { file in
                    HStack {
                        Image(systemName: "doc")
                            .foregroundStyle(CursorTheme.foregroundMuted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file.fileName).font(.system(size: 13, weight: .medium))
                            Text(spaces.spaceName(for: file.spaceId))
                                .font(.system(size: 11))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(LibraryGlassDesign.cardGlassFill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var plannerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Planner", subtitle: "Task calendar for the active Space.")
            if spaces.selectedSpace != nil {
                SpacesCalendarView(spaces: spaces)
            } else {
                emptyHint("Select a Space to view scheduled tasks on the calendar.")
                if let first = spaces.spaces.first {
                    Button("Open \(first.name)") {
                        Task { await spaces.openPlannerCalendar() }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Chat", subtitle: "Channels, DMs, threads, and realtime messaging.")
            Text("Open the Chat module for the full ClickUp-style inbox: Activity, DMs, channels, schedule send, and search.")
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Button("Open Chat") {
                NotificationCenter.default.post(name: .publshrSelectModule, object: AppModule.chat.rawValue)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    private var mediaSection: some View {
        let mediaSpaces = spaces.spaces.filter {
            $0.type == "publication" || $0.name.localizedCaseInsensitiveContains("media")
        }
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Media Monitoring", subtitle: "Coverage feeds and clipping detail.")
            if mediaSpaces.isEmpty {
                emptyHint("No publication spaces yet.")
            } else {
                ForEach(mediaSpaces) { space in
                    Text(space.name).font(.system(size: 13, weight: .medium))
                }
            }
            Button("Open Media Monitoring") {
                NotificationCenter.default.post(name: .publshrSelectModule, object: AppModule.mediaMonitoring.rawValue)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Settings", subtitle: "Workspace sync and preferences.")
            if spaces.isOffline {
                Label("Offline — showing cached data", systemImage: "wifi.slash")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            } else {
                Label("Connected to Supabase", systemImage: "cloud.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.accent)
            }
            Button("Refresh workspace data") {
                Task { await spaces.loadWorkspaceData() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Button("Open Publshr Settings") {
                NotificationCenter.default.post(name: .publshrOpenSettings, object: nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Chrome

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 18, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(CursorTheme.foregroundMuted)
    }

    private func metricCard(_ label: String, value: Int, warn: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                Text("\(value)")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(warn ? CursorTheme.error : CursorTheme.foreground)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(LibraryGlassDesign.cardGlassFill)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func panel<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            content()
        }
        .padding(14)
        .background(LibraryGlassDesign.cardGlassFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundStyle(CursorTheme.foregroundMuted)
            Spacer()
            Text(value).font(.system(size: 12, weight: .medium))
        }
    }
}
