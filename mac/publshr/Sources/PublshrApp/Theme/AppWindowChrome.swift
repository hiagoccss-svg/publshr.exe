import SwiftUI

/// Cursor Mac titlebar metrics — one band shared with system traffic lights.
///
/// Layout rules (enforced by `TitlebarToolbarRow` / `TitlebarToolbarSlot`):
/// - Row height is always `unifiedTitlebarRowHeight` (never driven by text or badges).
/// - Every interactive control sits in a `controlSize` × `controlSize` slot, center-aligned.
/// - Spacing between slots is always `toolbarItemSpacing`.
/// - Channel titles use `toolbarTitleFontSize` inside the same row height (no second toolbar band).
enum AppWindowChromeMetrics {
    /// Leading reserve for standard macOS close / minimize / zoom cluster (Ventura+).
    static let trafficLightLeadingInset: CGFloat = 84
    /// Gap between the green zoom button and the first app toolbar icon (Cursor Mac).
    static let afterTrafficLightGap: CGFloat = 12
    /// Vertical pad around measured traffic-light cluster inside the toolbar row.
    static let trafficLightVerticalPad: CGFloat = 8
    /// Minimum toolbar row height (matches native titlebar — do not go below ~44pt).
    static let minimumTitlebarRowHeight: CGFloat = 44
    /// Fallback when SwiftUI reports zero safe-area (pre-layout).
    static let fallbackTitlebarHeight: CGFloat = 28
    /// Default height of the unified titlebar row (overridden by live traffic-light measurement).
    static let trafficLightRowHeight: CGFloat = minimumTitlebarRowHeight
    /// Fallback top inset when traffic lights are not measurable yet (pre-layout).
    static let trafficLightVerticalAlignPadding: CGFloat = 8
    /// Hard cap so a bad traffic-light measure cannot consume the whole window.
    static let maxTitlebarTopPadding: CGFloat = 18
    /// Square chrome control — Cursor Mac titlebar hit target.
    static let controlSize: CGFloat = 32
    static let controlIconSize: CGFloat = 13
    static let controlCornerRadius: CGFloat = 6
    /// Channel glyph inside the title slot.
    static let channelIconSize: CGFloat = 17
    static let toolbarTitleFontSize: CGFloat = 13
    /// Gap between toolbar slots (icons, title cluster, spacers).
    static let toolbarItemSpacing: CGFloat = 8
    /// Far-left global cluster (settings, command, bell, menu) — same rhythm as `toolbarItemSpacing`.
    static let toolbarLeadingClusterSpacing: CGFloat = toolbarItemSpacing
    /// Editor column channel tools (pop-out, search, pin, …).
    static let toolbarEditorActionSpacing: CGFloat = 10
    /// Ask AI pill — same vertical footprint as chrome controls.
    static let askAIPillHeight: CGFloat = 24
    static let askAIPillHorizontalPadding: CGFloat = 10
    static let askAIPillCornerRadius: CGFloat = 12
    static let askAIIconSize: CGFloat = 11
    static let askAITextSize: CGFloat = 11
    /// Browser-style document tab chip in the titlebar.
    static let documentTabHeight: CGFloat = 28
    static let documentTabCornerRadius: CGFloat = 8
    static let documentTabHorizontalPadding: CGFloat = 10
    static let rowSpacing: CGFloat = 8
    /// @deprecated Use `toolbarItemSpacing` for titlebar rows.
    static let titlebarActionSpacing: CGFloat = toolbarItemSpacing
    static let trailingClusterSpacing: CGFloat = toolbarItemSpacing

    /// Unified toolbar row height — always matches the traffic-light band (never the inflated SwiftUI safe-area).
    static var unifiedTitlebarRowHeight: CGFloat {
        trafficLightRowHeight
    }
}

// MARK: - Titlebar layout primitives

/// Fixed-height titlebar band; children must use `TitlebarToolbarSlot` for controls.
struct TitlebarToolbarRow<Content: View>: View {
    @ObservedObject private var layout = TrafficLightLayoutStore.shared
    var leadingPadding: CGFloat = 0
    var trailingPadding: CGFloat = 0
    var itemSpacing: CGFloat = AppWindowChromeMetrics.toolbarItemSpacing
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: itemSpacing) {
            content()
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .frame(height: layout.rowHeight, alignment: .center)
    }
}

/// Forces any toolbar child into the shared control box so icons, menus, and avatars share one baseline.
struct TitlebarToolbarSlot<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(
                width: AppWindowChromeMetrics.controlSize,
                height: AppWindowChromeMetrics.controlSize,
                alignment: .center
            )
    }
}

/// Frosted titlebar background shared by the shell header.
struct AppWindowChromeBackground: View {
    var body: some View {
        Rectangle()
            .fill(CursorMacShellDesign.titleBarBackground)
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
    var isSelected: Bool
    var canClose: Bool
    var onSelect: () -> Void
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
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
                .fill(isSelected ? CursorTheme.tabActiveBackground : CursorTheme.tabInactiveBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppWindowChromeMetrics.documentTabCornerRadius, style: .continuous)
                .strokeBorder(CursorMacShellDesign.borderSubtle, lineWidth: isSelected ? 0 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
