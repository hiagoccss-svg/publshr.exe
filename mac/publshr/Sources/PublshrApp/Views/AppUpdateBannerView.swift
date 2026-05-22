import SwiftUI

struct AppUpdateBannerView: View {
    @ObservedObject var updates: AppUpdateViewModel

    var body: some View {
        if updates.hasPendingUpdate {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(CursorTheme.accent)
                Text(updates.statusLine)
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Button("Download") {
                    Task { await updates.downloadUpdate() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled({
                    if case .downloading = updates.phase { return true }
                    if case .installing = updates.phase { return true }
                    return false
                }())

                Button("Restart to update") {
                    Task { await updates.installAndRestart() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled({
                    switch updates.phase {
                    case .readyToInstall, .available:
                        return false
                    default:
                        return true
                    }
                }())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(CursorTheme.accent.opacity(0.12))
        }
    }
}
