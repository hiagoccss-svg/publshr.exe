import SwiftUI

/// Enterprise Media Monitoring — native inside Publshr.app (Supabase-backed).
struct MediaMonitoringModuleView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var media = MediaMonitoringViewModel()

    var body: some View {
        HStack(spacing: 0) {
            monitorSidebar
                .frame(width: 240)
            Rectangle()
                .fill(CursorTheme.borderSubtle)
                .frame(width: 1)
            articleColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if media.selectedResult != nil {
                Rectangle()
                    .fill(CursorTheme.borderSubtle)
                    .frame(width: 1)
                detailPanel
                    .frame(width: 300)
            }
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
        .onAppear { media.attach(auth: auth) }
        .onChange(of: auth.selectedMembership?.workspace.id) { _, _ in
            media.attach(auth: auth)
        }
    }

    private var monitorSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Media Monitoring")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)

            HStack(spacing: 6) {
                TextField("Monitor name", text: $media.newMonitorName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Button {
                    Task { await media.createMonitor() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)

            TextField("Keywords", text: $media.newMonitorKeywords)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .padding(8)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 10)
                .padding(.bottom, 8)

            if let err = media.errorMessage {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
            }

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(media.monitors) { monitor in
                        Button {
                            Task { await media.selectMonitor(monitor.id) }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(monitor.isActive ? Color.green : Color.gray.opacity(0.5))
                                    .frame(width: 6, height: 6)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(monitor.name)
                                        .font(.system(size: 12, weight: media.selectedMonitorId == monitor.id ? .semibold : .regular))
                                        .foregroundStyle(.white)
                                    Text(monitor.keywords)
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                media.selectedMonitorId == monitor.id
                                    ? Color.white.opacity(0.12)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
    }

    private var articleColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Coverage feed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if media.isLoading {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(14)

            if media.results.isEmpty {
                Text("No articles yet. Monitors sync from Supabase when coverage is ingested.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .padding(20)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(media.results) { row in
                            Button {
                                media.selectedResultId = row.id
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(row.title)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 8) {
                                        Text(row.sentiment.capitalized)
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                        if let pub = row.publicationName {
                                            Text(pub)
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.white.opacity(0.4))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    media.selectedResultId == row.id
                                        ? Color.white.opacity(0.1)
                                        : Color.white.opacity(0.04)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let article = media.selectedResult {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(article.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    if let author = article.author {
                        Text(author)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    if let url = article.url, let link = URL(string: url) {
                        Link("Open article", destination: link)
                            .font(.system(size: 12))
                    }
                    Text("Sentiment: \(article.sentiment)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .padding(16)
            }
        }
    }
}
