import SwiftUI

// MARK: - Native titlebar control (traffic-light row)

struct TitlebarChromeIconButton: View {
    let systemName: String
    var help: String = ""
    var isEnabled: Bool = true
    var isActive: Bool = false
    var isLoading: Bool = false
    var badgeCount: Int = 0
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.55)
                    } else {
                        Image(systemName: systemName)
                            .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .regular))
                            .symbolRenderingMode(.monochrome)
                    }
                }
                .foregroundStyle(foregroundColor)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.controlSize
                )
                .background(backgroundShape)
                .overlay(
                    RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                        .strokeBorder(strokeColor, lineWidth: isActive ? 1 : 0)
                )

                if badgeCount > 0 {
                    Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(CursorTheme.accent))
                        .offset(x: 6, y: -5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .help(help)
        .onHover { isHovered = $0 }
    }

    private var foregroundColor: Color {
        if !isEnabled { return LibraryGlassDesign.inkMuted.opacity(0.35) }
        if isActive { return LibraryGlassDesign.ink }
        return isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary
    }

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
            .fill(backgroundFill)
    }

    private var backgroundFill: Color {
        if isActive { return CursorTheme.tabActiveBackground }
        if isHovered && isEnabled { return CursorTheme.tabInactiveBackground.opacity(0.9) }
        return Color.clear
    }

    private var strokeColor: Color {
        isActive ? CursorMacShellDesign.border : Color.clear
    }
}

struct TitlebarChromeDivider: View {
    var body: some View {
        Rectangle()
            .fill(LibraryGlassDesign.hairline)
            .frame(width: 1, height: 16)
            .padding(.horizontal, 2)
    }
}

/// Workspace / profile menus — same chrome metrics as icon buttons.
struct TitlebarChromeMenuLabel: View {
    let title: String
    var systemImage: String? = nil
    var isActive: Bool = false

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .medium))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isActive || isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
        .padding(.horizontal, 8)
        .frame(height: AppWindowChromeMetrics.controlSize)
        .background(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                .fill(
                    isActive
                        ? LibraryGlassDesign.documentTabSelectedFill
                        : (isHovered ? Color.white.opacity(0.55) : Color.white.opacity(0.32))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                .strokeBorder(CursorMacShellDesign.borderSubtle, lineWidth: 0.5)
        )
        .onHover { isHovered = $0 }
    }
}
