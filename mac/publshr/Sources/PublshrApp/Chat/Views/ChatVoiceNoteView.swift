import SwiftUI

struct ChatVoiceRecorderSheet: View {
    @ObservedObject var chat: ChatViewModel
    @StateObject private var recorder = ChatVoiceRecorder()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Voice note")
                .font(.headline)

            Text(formatDuration(recorder.elapsedMs))
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundStyle(CursorTheme.foreground)

            WaveformPreview(samples: recorder.waveformSamples)
                .frame(height: 48)

            HStack(spacing: 16) {
                if recorder.isRecording {
                    Button(recorder.isPaused ? "Resume" : "Pause") {
                        recorder.isPaused ? recorder.resumeRecording() : recorder.pauseRecording()
                    }
                    Button("Stop") {
                        finishRecording()
                    }
                    .buttonStyle(ChatPrimaryButtonStyle())
                } else {
                    Button("Record") {
                        Task { try? await recorder.startRecording() }
                    }
                    .buttonStyle(ChatPrimaryButtonStyle())
                }
                Button("Cancel") {
                    recorder.cancelRecording()
                    dismiss()
                }
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func finishRecording() {
        guard let result = recorder.stopRecording() else { return }
        Task {
            await chat.sendVoiceNote(url: result.url, durationMs: result.durationMs, waveform: result.waveform)
            dismiss()
        }
    }

    private func formatDuration(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

struct WaveformPreview: View {
    let samples: [Float]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(samples.suffix(60).enumerated()), id: \.offset) { _, sample in
                RoundedRectangle(cornerRadius: 1)
                    .fill(CursorTheme.accent.opacity(0.8))
                    .frame(width: 3, height: max(4, CGFloat(sample) * 40))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ChatVoicePlaybackRow: View {
    let durationMs: Int
    let transcript: String?

    @State private var playbackRate: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundStyle(CursorTheme.accent)
                Text(formatDuration(durationMs))
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("Speed", selection: $playbackRate) {
                    Text("1×").tag(1.0)
                    Text("1.5×").tag(1.5)
                    Text("2×").tag(2.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            if let transcript {
                Text(transcript)
                    .font(.system(size: 11))
                    .foregroundStyle(CursorTheme.foregroundMuted)
            }
        }
        .padding(10)
        .background(CursorTheme.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatDuration(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%0d:%02d", s / 60, s % 60)
    }
}
