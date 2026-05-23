import SwiftUI

/// Native SwiftUI Media Monitoring — Supabase profiles + coverage results (no Electron shell).
struct MediaMonitoringModuleView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @EnvironmentObject private var media: MediaMonitoringViewModel

    var body: some View {
        HStack(spacing: 0) {
            profileList
                .frame(width: 220)
            Rectangle()
                .fill(CursorTheme.borderSubtle)
                .frame(width: 1)
            resultList
                .frame(width: 300)
            Rectangle()
                .fill(CursorTheme.borderSubtle)
                .frame(width: 1)
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CursorMacShellDesign.editorColumnBackground)
        .onAppear { media.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            media.attach(auth: auth)
        }
    }

    private var profileList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MONITORS")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 6)
            if media.isLoading && media.profiles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if media.profiles.isEmpty {
                Text("No monitors yet")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .padding(12)
                Spacer(minLength: 0)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(media.profiles) { profile in
                            Button {
                                Task { await media.selectProfile(profile.id) }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(profile.isActive ? Color.green : Color.gray.opacity(0.4))
                                        .frame(width: 6, height: 6)
                                    Text(profile.name)
                                        .font(.system(size: 13, weight: media.selectedProfileId == profile.id ? .semibold : .regular))
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 32)
                                .background(
                                    media.selectedProfileId == profile.id
                                        ? CursorTheme.tabActiveBackground
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
    }

    private var resultList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let err = media.errorMessage, !err.isEmpty {
                Text(err)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.error)
                    .padding(10)
            }
            if media.filteredResults.isEmpty {
                Text("No coverage items")
                    .font(.system(size: 12))
                    .foregroundStyle(CursorTheme.foregroundMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(media.filteredResults) { item in
                            Button {
                                media.selectResult(item.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(LibraryGlassDesign.ink)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 6) {
                                        sentimentBadge(item.sentiment)
                                        if media.savedResultIds.contains(item.id) {
                                            Image(systemName: "bookmark.fill")
                                                .font(.system(size: 9))
                                                .foregroundStyle(CursorTheme.accent)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    media.selectedResultId == item.id
                                        ? CursorTheme.tabActiveBackground
                                        : Color.clear
                                )
                            }
                            .buttonStyle(.plain)
                            Divider().opacity(0.35)
                        }
                    }
                }
            }
        }
    }

  @ViewBuilder
    private var detailPane: some View {
        if let item = media.selectedResult {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .semibold))
                    HStack(spacing: 12) {
                        sentimentBadge(item.sentiment)
                        if let author = item.author, !author.isEmpty {
                            Label(author, systemImage: "person")
                                .font(.system(size: 12))
                                .foregroundStyle(CursorTheme.foregroundMuted)
                        }
                    }
                    if let published = item.publishedAt {
                        Text(published)
                            .font(.system(size: 11))
                            .foregroundStyle(CursorTheme.foregroundMuted)
                    }
                    HStack(spacing: 16) {
                        metric("Reach", value: "\(item.reach)")
                        metric("Media value", value: String(format: "%.0f", item.mediaValue))
                        metric("Relevance", value: String(format: "%.0f%%", item.relevanceScore * 100))
                    }
                    if let url = item.url, let link = URL(string: url) {
                        Link("Open article", destination: link)
                            .font(.system(size: 13))
                    }
                    if !media.savedResultIds.contains(item.id) {
                        Button("Save to coverage book") {
                            Task { await media.saveSelectedResult() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        Label("Saved", systemImage: "bookmark.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(CursorTheme.accent)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CursorTheme.foregroundDim)
                Text("Select coverage")
                    .font(.system(size: 13))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func sentimentBadge(_ sentiment: String) -> some View {
        Text(sentiment.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(sentimentColor(sentiment).opacity(0.15))
            .foregroundStyle(sentimentColor(sentiment))
            .clipShape(Capsule())
    }

    private func sentimentColor(_ sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive": return .green
        case "negative": return .red
        case "mixed": return .orange
        default: return CursorTheme.foregroundMuted
        }
    }

    private func metric(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(CursorTheme.foregroundMuted)
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
    }
}
