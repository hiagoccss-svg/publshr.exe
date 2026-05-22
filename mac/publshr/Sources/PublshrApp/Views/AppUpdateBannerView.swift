import SwiftUI

/// Only surfaces rare install failures — successful live installs happen silently.
struct AppUpdateBannerView: View {
    @ObservedObject var updates: AppUpdateViewModel

    var body: some View {
        Group {
            if case .failed(let message) = updates.phase {
                errorBanner(message)
            } else if updates.isActivelyUpdating {
                progressBanner
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(CursorTheme.error)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(3)
            Spacer()
            Button("Retry") {
                Task { await updates.installLiveUpdateNow() }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(CursorTheme.error.opacity(0.1))
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private var progressBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
            Text(updates.statusLine)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(CursorTheme.accent.opacity(0.1))
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }
}
