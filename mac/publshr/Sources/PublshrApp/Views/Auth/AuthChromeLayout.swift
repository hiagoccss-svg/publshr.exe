import SwiftUI

/// Shared macOS-native chrome for sign-in and workspace selection (readable contrast, card layout).
enum AuthChromeLayout {
    static let cardMaxWidth: CGFloat = 420
    static let horizontalPadding: CGFloat = 48
    static let topChromeInset: CGFloat = 52

    static var screenBackground: some View {
        CursorTheme.authBackground.ignoresSafeArea()
    }

    static func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(28)
        .frame(maxWidth: cardMaxWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CursorTheme.authCard)
                .shadow(color: CursorTheme.authCardShadow, radius: 24, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(CursorTheme.border.opacity(0.35), lineWidth: 1)
        )
    }

    static func primaryButton(title: String, isLoading: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(CursorTheme.buttonForeground)
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(CursorTheme.buttonForeground)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(CursorTheme.buttonBackground)
        )
        .disabled(isLoading)
    }

    static func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
        .foregroundStyle(CursorTheme.foreground)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(CursorTheme.inputBorder, lineWidth: 1)
        )
    }

    static func modeSegment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? CursorTheme.foreground : CursorTheme.foregroundMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? CursorTheme.authCard : Color.clear)
                        .shadow(color: selected ? CursorTheme.authCardShadow : .clear, radius: 4, y: 1)
                )
        }
        .buttonStyle(.plain)
    }

    static func labeledField<Content: View>(
        _ label: String,
        @ViewBuilder field: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CursorTheme.foregroundMuted)
            field()
                .font(.system(size: 14))
                .foregroundStyle(CursorTheme.foreground)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CursorTheme.inputBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CursorTheme.inputBorder, lineWidth: 1)
                )
        }
    }
}
