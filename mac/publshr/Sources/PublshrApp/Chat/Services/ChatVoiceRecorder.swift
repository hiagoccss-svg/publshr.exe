import AVFoundation
import Foundation

/// Native microphone capture for voice notes (Phase 3).
@MainActor
final class ChatVoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var elapsedMs: Int = 0
    @Published var waveformSamples: [Float] = []
    @Published var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var outputURL: URL?

    func requestPermission() async -> Bool {
        let granted = await SystemPermissionStore.ensureMicrophoneAccess()
        permissionDenied = !granted && SystemPermissionStore.isMicrophoneDenied
        return granted
    }

    func startRecording() async throws -> URL {
        guard await requestPermission() else {
            throw ChatVoiceError.permissionDenied
        }

        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent("voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        recorder?.record()
        outputURL = url
        isRecording = true
        isPaused = false
        elapsedMs = 0
        waveformSamples = []
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        return url
    }

    func pauseRecording() {
        recorder?.pause()
        isPaused = true
    }

    func resumeRecording() {
        recorder?.record()
        isPaused = false
    }

    func stopRecording() -> (url: URL, durationMs: Int, waveform: [Double])? {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        isRecording = false
        isPaused = false
        guard let url = outputURL else { return nil }
        let duration = max(elapsedMs, 1)
        let wave = waveformSamples.map { Double($0) }
        recorder = nil
        return (url, duration, wave)
    }

    func cancelRecording() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        if let url = outputURL { try? FileManager.default.removeItem(at: url) }
        isRecording = false
        isPaused = false
        elapsedMs = 0
        waveformSamples = []
        recorder = nil
        outputURL = nil
    }

    private func tick() {
        guard isRecording, !isPaused else { return }
        elapsedMs += 100
        recorder?.updateMeters()
        let power = recorder?.averagePower(forChannel: 0) ?? -160
        let normalized = max(0, min(1, (power + 60) / 60))
        waveformSamples.append(normalized)
        if waveformSamples.count > 120 { waveformSamples.removeFirst() }
    }
}

enum ChatVoiceError: LocalizedError {
    case permissionDenied
    var errorDescription: String? { "Microphone access is required for voice notes." }
}
