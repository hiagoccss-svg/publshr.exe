import SwiftUI

/// Playback UI for existing voice-note attachments (recording removed).
struct ChatVoicePlaybackRow: View {
    let durationMs: Int
    var transcript: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(durationLabel)
                    .font(.system(size: 12, weight: .medium))
                if let transcript, !transcript.isEmpty {
                    Text(transcript)
                        .font(.system(size: 11))
                        .foregroundStyle(CursorTheme.foregroundMuted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(LibraryGlassDesign.cardGlassFill.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var durationLabel: String {
        let s = max(1, durationMs / 1000)
        return "Voice note · \(s)s"
    }
}
