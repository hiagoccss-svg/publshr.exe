import AppKit
import Combine
import SwiftUI

/// Live titlebar geometry from system traffic-light buttons (single source of truth).
@MainActor
final class TrafficLightLayoutStore: ObservableObject {
    static let shared = TrafficLightLayoutStore()

    /// Toolbar row height — follows measured traffic-light cluster (Cursor Mac uses full system size).
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

        if let metrics = Self.measureTrafficLights(in: window, contentView: contentView) {
            leadingInset = metrics.leadingInset
            titlebarTopPadding = Self.clampTopPadding(metrics.titlebarTopPadding)
            rowHeight = metrics.rowHeight
        } else {
            leadingInset = AppWindowChromeMetrics.trafficLightLeadingInset
            titlebarTopPadding = Self.clampTopPadding(AppWindowChromeMetrics.trafficLightVerticalAlignPadding)
            rowHeight = AppWindowChromeMetrics.trafficLightRowHeight
        }

        syncAdditionalSafeArea(contentView: contentView)

        guard generation == refreshGeneration else { return }
    }

    /// Avoid negative top inset — it compresses the titlebar band and makes traffic lights look undersized.
    private func syncAdditionalSafeArea(contentView: NSView) {
        var extra = contentView.additionalSafeAreaInsets
        if abs(extra.top) > 0.5 {
            extra.top = 0
            contentView.additionalSafeAreaInsets = extra
        }
    }

    private struct TrafficMetrics {
        var leadingInset: CGFloat
        var titlebarTopPadding: CGFloat
        var rowHeight: CGFloat
    }

    private static func clampTopPadding(_ value: CGFloat) -> CGFloat {
        min(max(0, value), AppWindowChromeMetrics.maxTitlebarTopPadding)
    }

    private static func measureTrafficLights(in window: NSWindow, contentView: NSView) -> TrafficMetrics? {
        guard let close = window.standardWindowButton(.closeButton),
              let container = close.superview else { return nil }

        let closeRect = container.convert(close.frame, to: contentView)
        let mini = window.standardWindowButton(.miniaturizeButton)
        let zoom = window.standardWindowButton(.zoomButton)
        let miniRect = mini.map { container.convert($0.frame, to: contentView) }
        let zoomRect = zoom.map { container.convert($0.frame, to: contentView) }

        let clusterMaxX = max(
            closeRect.maxX,
            miniRect?.maxX ?? closeRect.maxX,
            zoomRect?.maxX ?? closeRect.maxX
        )
        let clusterMinY = min(
            closeRect.minY,
            miniRect?.minY ?? closeRect.minY,
            zoomRect?.minY ?? closeRect.minY
        )
        let clusterMaxY = max(
            closeRect.maxY,
            miniRect?.maxY ?? closeRect.maxY,
            zoomRect?.maxY ?? closeRect.maxY
        )
        let clusterHeight = max(clusterMaxY - clusterMinY, closeRect.height)

        let trailingX = clusterMaxX + AppWindowChromeMetrics.afterTrafficLightGap
        let row = max(
            AppWindowChromeMetrics.minimumTitlebarRowHeight,
            clusterHeight + AppWindowChromeMetrics.trafficLightVerticalPad * 2
        )

        let contentHeight = max(contentView.bounds.height, 1)
        let clusterCenterFromTop: CGFloat
        if contentView.isFlipped {
            // SwiftUI NSHostingView — origin top-left.
            clusterCenterFromTop = (clusterMinY + clusterMaxY) * 0.5
        } else {
            clusterCenterFromTop = contentHeight - (clusterMinY + clusterMaxY) * 0.5
        }

        guard clusterCenterFromTop.isFinite,
              clusterCenterFromTop >= 0,
              clusterCenterFromTop <= contentHeight * 0.25
        else { return nil }

        let topPad = clampTopPadding(clusterCenterFromTop - row * 0.5)

        return TrafficMetrics(
            leadingInset: max(trailingX, AppWindowChromeMetrics.trafficLightLeadingInset),
            titlebarTopPadding: topPad,
            rowHeight: row
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
        let top = min(store.titlebarTopPadding, AppWindowChromeMetrics.maxTitlebarTopPadding)
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: top + store.rowHeight
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
