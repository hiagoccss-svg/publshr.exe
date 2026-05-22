import AppKit
import Combine
import SwiftUI

/// Live titlebar geometry from system traffic-light buttons (single source of truth).
@MainActor
final class TrafficLightLayoutStore: ObservableObject {
    static let shared = TrafficLightLayoutStore()

    /// Height of the custom toolbar row (fixed — matches Cursor Mac chrome controls).
    @Published private(set) var rowHeight: CGFloat = AppWindowChromeMetrics.trafficLightRowHeight
    /// Leading reserve through the traffic-light cluster (SwiftUI spacer width).
    @Published private(set) var leadingInset: CGFloat = AppWindowChromeMetrics.trafficLightLeadingInset
    /// Top padding so toolbar icons share the traffic-light vertical centerline.
    @Published private(set) var titlebarTopPadding: CGFloat = 0

    private var refreshGeneration = 0

    private init() {}

    func requestRefresh(from window: NSWindow?) {
        refreshGeneration += 1
        let generation = refreshGeneration
        guard let window else { return }
        apply(to: window, generation: generation)
    }

    func apply(to window: NSWindow) {
        refreshGeneration += 1
        apply(to: window, generation: refreshGeneration)
    }

    private func apply(to window: NSWindow, generation: Int) {
        guard let contentView = window.contentView else { return }

        let row = AppWindowChromeMetrics.trafficLightRowHeight
        rowHeight = row

        if let metrics = Self.measureTrafficLights(in: window, contentView: contentView) {
            leadingInset = metrics.leadingInset
            let raw = max(0, metrics.midYFromTop - row * 0.5)
            titlebarTopPadding = min(raw, Self.maxTitlebarTopPadding)
        } else {
            leadingInset = AppWindowChromeMetrics.trafficLightLeadingInset
            titlebarTopPadding = AppWindowChromeMetrics.trafficLightVerticalAlignPadding
        }

        syncAdditionalSafeArea(contentView: contentView, rowHeight: row)

        guard generation == refreshGeneration else { return }
    }

    /// Keeps SwiftUI layout from stacking extra top inset on top of our measured titlebar band.
    private func syncAdditionalSafeArea(contentView: NSView, rowHeight: CGFloat) {
        let reportedTop = contentView.safeAreaInsets.top
        let band = titlebarTopPadding + rowHeight
        var extra = contentView.additionalSafeAreaInsets
        let desiredTop = reportedTop > band + 0.5 ? band - reportedTop : 0
        if abs(extra.top - desiredTop) > 0.5 {
            extra.top = desiredTop
            contentView.additionalSafeAreaInsets = extra
        }
    }

    private struct TrafficMetrics {
        var leadingInset: CGFloat
        var midYFromTop: CGFloat
    }

    /// Max top padding before we treat measurement as invalid (prevents shell pinned to window bottom).
    private static let maxTitlebarTopPadding: CGFloat = 18

    private static func measureTrafficLights(in window: NSWindow, contentView: NSView) -> TrafficMetrics? {
        guard let close = window.standardWindowButton(.closeButton),
              let container = close.superview else { return nil }

        let closeRect = container.convert(close.frame, to: contentView)
        let zoom = window.standardWindowButton(.zoomButton)
        let zoomRect = zoom.map { container.convert($0.frame, to: contentView) }
        let trailingX = (zoomRect?.maxX ?? closeRect.maxX) + 8

        let contentHeight = max(contentView.bounds.height, 1)
        // SwiftUI hosting views are often flipped (origin top-left); AppKit windows are not.
        let midYFromTop: CGFloat
        if contentView.isFlipped {
            midYFromTop = closeRect.midY
        } else {
            midYFromTop = contentHeight - closeRect.midY
        }

        guard midYFromTop.isFinite,
              midYFromTop >= 0,
              midYFromTop <= contentHeight * 0.25
        else { return nil }

        return TrafficMetrics(
            leadingInset: max(trailingX, 68),
            midYFromTop: midYFromTop
        )
    }
}

/// Keeps `TrafficLightLayoutStore` in sync whenever the window lays out traffic lights.
struct TrafficLightLayoutRefreshView: NSViewRepresentable {
    func makeNSView(context: Context) -> TrafficLightLayoutRefreshNSView {
        TrafficLightLayoutRefreshNSView()
    }

    func updateNSView(_ nsView: TrafficLightLayoutRefreshNSView, context: Context) {
        nsView.refresh()
    }
}

final class TrafficLightLayoutRefreshNSView: NSView {
    override var intrinsicContentSize: NSSize {
        let store = TrafficLightLayoutStore.shared
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: store.titlebarTopPadding + store.rowHeight
        )
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        refresh()
    }

    override func layout() {
        super.layout()
        refresh()
    }

    func refresh() {
        guard let window else { return }
        TrafficLightLayoutStore.shared.apply(to: window)
    }
}
