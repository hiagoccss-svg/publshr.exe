import SwiftUI

struct AppUpdateBannerView: View {
    @ObservedObject var updates: AppUpdateViewModel

    var body: some View {
        Group {
            if updates.hasPendingUpdate || updates.errorMessage != nil {
                bannerContent
            }
        }
    }

    @ViewBuilder
    private var bannerContent: some View {
        HStack(spacing: 10) {
            Image(systemName: updates.errorMessage != nil ? "exclamationmark.triangle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(updates.errorMessage != nil ? CursorTheme.error : CursorTheme.accent)

            Text(updates.statusLine)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foreground)
                .lineLimit(2)

            Spacer()

            if updates.errorMessage != nil {
                Button("Retry") {
                    Task { await updates.checkForUpdates(silent: false) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else if updates.canInstallNow {
                Button("Update now") {
                    Task { await updates.updateNow() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isBusy)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(updates.errorMessage != nil ? CursorTheme.error.opacity(0.1) : CursorTheme.accent.opacity(0.12))
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.border).frame(height: 1)
        }
    }

    private var isBusy: Bool {
        switch updates.phase {
        case .downloading, .installing, .checking:
            return true
        default:
            return false
        }
    }
}
