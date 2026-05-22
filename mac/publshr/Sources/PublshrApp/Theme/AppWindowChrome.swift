import SwiftUI

/// Pinterest / notes-app reference — one titlebar band; controls vertically center on the traffic-light row.
enum AppWindowChromeMetrics {
    /// Leading reserve for standard macOS close / minimize / zoom cluster.
    static let trafficLightLeadingInset: CGFloat = 72
    /// Fallback when SwiftUI reports zero safe-area (pre-layout).
    static let fallbackTitlebarHeight: CGFloat = 28
    /// Height of the system titlebar row where traffic lights are drawn (fixed — do not use safe-area height for layout).
    static let trafficLightRowHeight: CGFloat = 28
    /// Optical nudge so controls line up with the system close button (macOS centers lights ~12pt from window top).
    static let trafficLightVerticalAlignPadding: CGFloat = 1
    /// Square chrome control (edit, pop-out, close tab) — matches close-button visual size.
    static let controlSize: CGFloat = 24
    static let controlIconSize: CGFloat = 11
    static let controlCornerRadius: CGFloat = 6
    /// Ask AI pill — same vertical footprint as chrome controls.
    static let askAIPillHeight: CGFloat = 24
    static let askAIPillHorizontalPadding: CGFloat = 10
    static let askAIPillCornerRadius: CGFloat = 12
    static let askAIIconSize: CGFloat = 11
    static let askAITextSize: CGFloat = 11
    /// Browser-style document tab chip in the titlebar.
    static let documentTabHeight: CGFloat = 24
    static let documentTabCornerRadius: CGFloat = 8
    static let documentTabHorizontalPadding: CGFloat = 10
    static let rowSpacing: CGFloat = 8
    static let titlebarActionSpacing: CGFloat = 4
    static let trailingClusterSpacing: CGFloat = 6

    /// Unified toolbar row height — always matches the traffic-light band (never the inflated SwiftUI safe-area).
    static var unifiedTitlebarRowHeight: CGFloat {
        trafficLightRowHeight
    }
}

/// Frosted titlebar background shared by the shell header.
struct AppWindowChromeBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .background(LibraryGlassDesign.headerGlass)
    }
}

/// Pill-shaped Ask AI control (reference: darker pink glass on the titlebar).
struct AskAIChromeButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: AppWindowChromeMetrics.askAIIconSize, weight: .semibold))
                Text("Ask AI")
                    .font(.system(size: AppWindowChromeMetrics.askAITextSize, weight: .semibold))
            }
            .foregroundStyle(LibraryGlassDesign.ink)
            .padding(.horizontal, AppWindowChromeMetrics.askAIPillHorizontalPadding)
            .frame(height: AppWindowChromeMetrics.askAIPillHeight)
            .background(
                Capsule(style: .continuous)
                    .fill(LibraryGlassDesign.askAIPillFill)
                    .background(.ultraThinMaterial)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(LibraryGlassDesign.askAIPillStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Open AI assistant")
    }
}

/// Minimal square icon aligned to traffic-light baseline (pane edit, pop-out, close tab).
struct ChromeSquareButton: View {
    let systemName: String
    var help: String = ""
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: AppWindowChromeMetrics.controlIconSize, weight: .regular))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(isHovered ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                .frame(
                    width: AppWindowChromeMetrics.controlSize,
                    height: AppWindowChromeMetrics.controlSize
                )
                .background(
                    RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.55) : Color.white.opacity(0.42))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppWindowChromeMetrics.controlCornerRadius, style: .continuous)
                        .strokeBorder(LibraryGlassDesign.hairline, lineWidth: 1)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}

/// Browser-style tab chip for the unified titlebar.
struct ChromeDocumentTab: View {
    let title: String
    let iconSystemName: String
    var isSelected: Bool
    var canClose: Bool
    var onSelect: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconSystemName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isSelected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkMuted)
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? LibraryGlassDesign.ink : LibraryGlassDesign.inkSecondary)
                .lineLimit(1)
            if canClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(LibraryGlassDesign.inkMuted)
                        .frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .help("Close tab")
            }
        }
        .padding(.horizontal, AppWindowChromeMetrics.documentTabHorizontalPadding)
        .frame(height: AppWindowChromeMetrics.documentTabHeight)
        .background(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.documentTabCornerRadius, style: .continuous)
                .fill(isSelected ? LibraryGlassDesign.documentTabSelectedFill : LibraryGlassDesign.documentTabFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.documentTabCornerRadius, style: .continuous)
                .strokeBorder(LibraryGlassDesign.hairline, lineWidth: isSelected ? 1 : 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
