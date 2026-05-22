import SwiftUI

/// Slack-style workspace search — tabs, scope, live query (⌘⇧F / command palette).
struct ChatSearchSheet: View {
    @ObservedObject var chat: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var queryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            scopeBar
            tabBar
            if let hint = searchHint {
                Text(hint)
                    .font(.system(size: 11))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
            }
            resultsList
        }
        .frame(width: 560, height: 480)
        .onAppear {
            queryFocused = true
            if chat.searchScope == .channel, chat.selectedChannel == nil {
                chat.searchScope = .workspace
            }
            Task { await chat.runGlobalSearch() }
        }
        .onChange(of: chat.globalSearchQuery) { _, _ in
            chat.scheduleGlobalSearch()
        }
        .onChange(of: chat.searchTab) { _, _ in
            Task { await chat.runGlobalSearch() }
        }
        .onChange(of: chat.searchScope) { _, _ in
            Task { await chat.runGlobalSearch() }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            TextField(searchPlaceholder, text: $chat.globalSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($queryFocused)
                .onSubmit { Task { await chat.runGlobalSearch() } }
            if chat.isSearchLoading {
                ProgressView()
                    .controlSize(.small)
            }
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(14)
    }

    private var searchPlaceholder: String {
        switch chat.searchScope {
        case .workspace:
            return "Search messages, channels, people…"
        case .channel:
            return "Search in \(chat.selectedChannel?.sidebarTitle ?? "channel")…"
        }
    }

    private var scopeBar: some View {
        HStack(spacing: 8) {
            Text("Scope")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            Picker("Scope", selection: $chat.searchScope) {
                ForEach(ChatSearchScope.allCases, id: \.self) { scope in
                    Text(scope.label).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(chat.selectedChannel == nil)
            Spacer()
            if chat.isOffline {
                Label("Offline", systemImage: "wifi.slash")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChatSearchTab.allCases) { tab in
                    searchTabPill(tab)
                }
            }
            .padding(.horizontal, 14)
        }
        .padding(.bottom, 8)
    }

    private func searchTabPill(_ tab: ChatSearchTab) -> some View {
        let selected = chat.searchTab == tab
        return Button {
            chat.searchTab = tab
        } label: {
            Text(tab.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(selected ? Color.white : LibraryGlassDesign.inkSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(selected ? LibraryGlassDesign.primaryCTA : LibraryGlassDesign.sidebarGlassFill)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultsList: some View {
        if chat.globalSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            emptyState(
                icon: "text.magnifyingglass",
                title: "Search your workspace",
                detail: "Try a channel name, person, or words from a message. Use tabs to narrow results."
            )
        } else if chat.isSearchLoading, chat.searchResults.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Searching…")
                    .font(.system(size: 12))
                    .foregroundStyle(LibraryGlassDesign.inkMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if chat.searchResults.isEmpty {
            emptyState(
                icon: "magnifyingglass",
                title: "No results",
                detail: chat.searchError ?? "Try different keywords or switch to All."
            )
        } else {
            List(chat.searchResults) { hit in
                Button {
                    chat.activateSearchHit(hit)
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon(for: hit.kind))
                            .font(.system(size: 13))
                            .foregroundStyle(LibraryGlassDesign.primaryCTA)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(hit.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(LibraryGlassDesign.ink)
                                .lineLimit(2)
                            Text(hit.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(LibraryGlassDesign.inkMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(kindLabel(hit.kind))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(LibraryGlassDesign.inkMuted)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }

    private var searchHint: String? {
        if let err = chat.searchError { return err }
        let q = chat.globalSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }
        return "\(chat.searchResults.count) result\(chat.searchResults.count == 1 ? "" : "s") · \(chat.searchTab.label)"
    }

    private func emptyState(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(LibraryGlassDesign.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func icon(for kind: ChatSearchKind) -> String {
        switch kind {
        case .message: "bubble.left"
        case .file: "doc"
        case .voice: "waveform"
        case .user: "person"
        case .channel: "number"
        case .task: "checklist"
        }
    }

    private func kindLabel(_ kind: ChatSearchKind) -> String {
        switch kind {
        case .message: "Message"
        case .file: "File"
        case .voice: "Voice"
        case .user: "Person"
        case .channel: "Channel"
        case .task: "Task"
        }
    }
}
