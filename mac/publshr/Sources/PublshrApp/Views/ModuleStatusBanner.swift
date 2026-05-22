import SwiftUI

/// Inline module error / offline notice (chat, spaces).
struct ModuleStatusBanner: View {
    enum Style {
        case error
        case warning
    }

    let text: String
    var style: Style = .error

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style == .error ? "exclamationmark.triangle.fill" : "wifi.exclamationmark")
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(LibraryGlassDesign.hairline).frame(height: 1)
        }
    }

    private var foreground: Color {
        style == .error ? Color(hex: 0x8B1E1E) : Color(hex: 0x6B5A12)
    }

    private var background: Color {
        style == .error ? Color(hex: 0xFCE8E8) : Color(hex: 0xFFF8E6)
    }
}
