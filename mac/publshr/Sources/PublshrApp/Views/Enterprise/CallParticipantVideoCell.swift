import LiveKit
import SwiftUI

struct CallParticipantVideoCell: View {
    let tile: CallVideoTile
    let resolvedName: String

    private let tileHeight: CGFloat = 140

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if tile.isCameraEnabled, let track = tile.videoTrack {
                LiveKitVideoTrackView(track: track, layoutMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: tileHeight, maxHeight: tileHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.75))
                    .frame(maxWidth: .infinity, minHeight: tileHeight, maxHeight: tileHeight)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: tile.isLocal ? "person.crop.circle" : "mic.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(tile.isCameraEnabled ? "Starting video…" : "Audio only")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
            }

            HStack(spacing: 6) {
                if tile.isLocal {
                    Text("You")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CursorTheme.accent)
                        .clipShape(Capsule())
                }
                Text(resolvedName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
