import SwiftUI
import UniformTypeIdentifiers

/// Root view for an isolated chat pop-out window.
struct SessionPopOutRootView: View {
    @ObservedObject var session: ChatChannelSession
    @State private var editText = ""

    var body: some View {
        HStack(spacing: 0) {
            SessionConversationView(session: session, editText: $editText)
            if session.showThreadPanel {
                SessionThreadPanel(session: session)
            }
        }
        .background(CursorTheme.chatBackground)
        .preferredColorScheme(.light)
        .sheet(isPresented: Binding(
            get: { session.editingMessageId != nil },
            set: { if !$0 { session.editingMessageId = nil } }
        )) {
            sessionEditSheet
        }
    }

    private var sessionEditSheet: some View {
        VStack(spacing: 12) {
            Text("Edit message").font(.headline)
            TextField("Message", text: $editText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...8)
            HStack {
                Button("Cancel") { session.editingMessageId = nil }
                Spacer()
                Button("Save") {
                    guard let id = session.editingMessageId,
                          let msg = session.messages.first(where: { $0.id == id }) else { return }
                    Task {
                        await session.editMessage(msg, newBody: editText)
                        session.editingMessageId = nil
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

/// Conversation surface for dedicated pop-out windows (`ChatChannelSession`).
struct SessionConversationView: View {
    @ObservedObject var session: ChatChannelSession
    @Binding var editText: String
    @State private var showFileImporter = false
    @StateObject private var voiceRecorder = ChatVoiceRecorder()
    @State private var voiceCaptureActive = false

    var body: some View {
        VStack(spacing: 0) {
            sessionHeader
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.mainChannelMessages) { msg in
                            sessionMessageRow(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: session.mainChannelMessages.count) { _, _ in
                    if let last = session.mainChannelMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            if let progress = session.uploadProgress {
                ProgressView(value: progress).padding(.horizontal, 12)
            }

            sessionComposer
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image, .pdf, .data], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await session.uploadFile(from: url) }
            }
        }
    }

    private var sessionHeader: some View {
        HStack {
            Text(session.channel.displayTitle)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            if let typing = session.typingLabel {
                ChatTypingIndicatorView(label: typing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(CursorTheme.borderSubtle).frame(height: 1)
        }
    }

    private func sessionMessageRow(_ message: ChatMessage) -> some View {
        ChatMessageBubbleView(
            message: message,
            authorName: session.displayName(for: message.userId),
            authorProfile: session.profiles[message.userId],
            isOwn: message.userId == session.currentUserId,
            showAvatar: true,
            reactions: session.reactions[message.id] ?? [],
            links: session.links[message.id] ?? [],
            threadReplyCount: session.threadCounts[message.id] ?? 0,
            voiceTranscript: session.voiceTranscripts[message.id],
            onReaction: { emoji in Task { await session.toggleReaction(messageId: message.id, emoji: emoji) } },
            onThread: { Task { await session.openThread(message) } },
            onEdit: {
                session.editingMessageId = message.id
                editText = message.body ?? ""
            },
            onDelete: { Task { await session.deleteMessage(message) } }
        )
    }

    private var sessionComposer: some View {
        VStack(spacing: 6) {
            if voiceCaptureActive, session.permissions.canUseVoiceNotes {
                ChatInlineVoiceRecorderBar(
                    recorder: voiceRecorder,
                    onSend: { url, ms, wave in
                        voiceCaptureActive = false
                        Task { await session.sendVoiceNote(url: url, durationMs: ms, waveform: wave) }
                    },
                    onCancel: {
                        voiceRecorder.cancelRecording()
                        voiceCaptureActive = false
                    }
                )
                .padding(.horizontal, 12)
            } else {
            HStack(alignment: .bottom, spacing: 8) {
                if session.permissions.canUseVoiceNotes {
                    Button {
                        voiceCaptureActive.toggle()
                        if voiceCaptureActive {
                            Task { try? await voiceRecorder.startRecording() }
                        } else {
                            voiceRecorder.cancelRecording()
                        }
                    } label: {
                        Image(systemName: voiceCaptureActive ? "mic.fill" : "mic")
                            .foregroundStyle(CursorTheme.foregroundDim)
                    }
                    .buttonStyle(.plain)
                }
                TextField("Message…", text: $session.composerText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .lineLimit(1...6)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(CursorTheme.border, lineWidth: 1))
                    .onChange(of: session.composerText) { _, _ in session.composerChanged() }
                Button { Task { await session.sendMessage() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(CursorTheme.accent)
                }
                .buttonStyle(.plain)
                .disabled(session.composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            }
        }
        .background(Color.white)
    }
}

struct SessionThreadPanel: View {
    @ObservedObject var session: ChatChannelSession

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Thread").font(.system(size: 12, weight: .semibold))
                Spacer()
                Button { session.showThreadPanel = false } label: {
                    Image(systemName: "xmark").font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(session.threadMessages) { msg in
                        ChatMessageBubbleView(
                            message: msg,
                            authorName: session.displayName(for: msg.userId),
                            authorProfile: session.profiles[msg.userId],
                            isOwn: msg.userId == session.currentUserId,
                            showAvatar: true
                        )
                    }
                }
                .padding(12)
            }
            HStack {
                TextField("Reply…", text: $session.threadComposerText)
                    .textFieldStyle(.roundedBorder)
                Button("Send") { Task { await session.sendThreadReply() } }
            }
            .padding(12)
        }
        .frame(width: 300)
        .background(Color.white)
    }
}

struct ChatVoiceRecorderSheetForSession: View {
    @ObservedObject var session: ChatChannelSession
    @StateObject private var recorder = ChatVoiceRecorder()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChatVoiceRecorderSheetContent(recorder: recorder) { url, ms, wave in
            Task { await session.sendVoiceNote(url: url, durationMs: ms, waveform: wave) }
            dismiss()
        } onCancel: {
            recorder.cancelRecording()
            dismiss()
        }
    }
}

/// Shared voice sheet body for IDE + pop-out.
struct ChatVoiceRecorderSheetContent: View {
    @ObservedObject var recorder: ChatVoiceRecorder
    let onFinish: (URL, Int, [Double]) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Voice note").font(.headline)
            if recorder.permissionDenied {
                Text("Microphone access is required. Open System Settings → Privacy & Security → Microphone and enable Publshr.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Text(formatDuration(recorder.elapsedMs))
                .font(.system(size: 28, weight: .light, design: .monospaced))
            WaveformPreview(samples: recorder.waveformSamples).frame(height: 48)
            HStack(spacing: 16) {
                if recorder.isRecording {
                    Button(recorder.isPaused ? "Resume" : "Pause") {
                        recorder.isPaused ? recorder.resumeRecording() : recorder.pauseRecording()
                    }
                    Button("Stop") {
                        if let r = recorder.stopRecording() { onFinish(r.url, r.durationMs, r.waveform) }
                    }
                    .buttonStyle(ChatPrimaryButtonStyle())
                } else {
                    Button("Record") { Task { try? await recorder.startRecording() } }
                        .buttonStyle(ChatPrimaryButtonStyle())
                }
                Button("Cancel", action: onCancel)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    private func formatDuration(_ ms: Int) -> String {
        let s = ms / 1000
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
