import SwiftUI

/// ClickUp-style typing indicator with animated dots.
struct ChatTypingIndicatorView: View {
    let label: String
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(CursorTheme.accent.opacity(0.7))
                        .frame(width: 5, height: 5)
                        .offset(y: phase == i ? -3 : 0)
                }
            }
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(LibraryGlassDesign.cardGlassFill.opacity(0.85))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(CursorTheme.borderSubtle, lineWidth: 1))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}

extension ChatViewModel {
    var typingSummary: String {
        let names = typingUsers.map(\.displayName)
        if names.isEmpty { return "" }
        if names.count == 1 { return "\(names[0]) is typing" }
        if names.count == 2 { return "\(names[0]) and \(names[1]) are typing" }
        return "\(names[0]) and \(names.count - 1) others are typing"
    }
}
