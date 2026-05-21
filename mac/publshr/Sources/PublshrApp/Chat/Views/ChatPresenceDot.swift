import SwiftUI

struct ChatPresenceDot: View {
    let status: ChatPresenceStatus
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(CursorTheme.panelBackground, lineWidth: 1.5)
            )
    }

    private var color: Color {
        switch status {
        case .online: Color(hex: 0x3FB950)
        case .away: Color(hex: 0xD29922)
        case .busy, .inMeeting: Color(hex: 0xF85149)
        case .offline, .invisible: Color(hex: 0x6E6E6E)
        }
    }
}
