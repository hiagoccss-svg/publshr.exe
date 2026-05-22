import AppKit
import SwiftUI

/// Live metrics from system traffic-light buttons so SwiftUI toolbar icons share their row.
enum TrafficLightLayoutMetrics {
    static let fallbackLeadingInset: CGFloat = 80
    static let fallbackIconOffsetY: CGFloat = 0

    @MainActor
    static func measure(in window: NSWindow?) -> (leadingInset: CGFloat, iconOffsetY: CGFloat) {
        guard let window,
              let close = window.standardWindowButton(.closeButton) else {
            return (fallbackLeadingInset, fallbackIconOffsetY)
        }
        let zoom = window.standardWindowButton(.zoomButton)
        let trailing = (zoom?.frame.maxX ?? close.frame.maxX) + 8
        let rowHeight = AppWindowChromeMetrics.trafficLightRowHeight
        let contentHeight = window.contentView?.bounds.height ?? rowHeight
        let trafficCenterFromTop = contentHeight - close.frame.midY
        let iconOffsetY = trafficCenterFromTop - rowHeight * 0.5
        return (max(trailing, 68), iconOffsetY)
    }
}

/// Reserves leading space matching the traffic-light cluster width.
struct TrafficLightLeadingSpacer: NSViewRepresentable {
    @Binding var width: CGFloat

    func makeNSView(context: Context) -> TrafficLightLayoutNSView {
        let view = TrafficLightLayoutNSView()
        view.onMetricsChange = { newWidth, _ in
            if abs(width - newWidth) > 0.5 {
                width = newWidth
            }
        }
        return view
    }

    func updateNSView(_ nsView: TrafficLightLayoutNSView, context: Context) {
        nsView.onMetricsChange = { newWidth, _ in
            if abs(width - newWidth) > 0.5 {
                width = newWidth
            }
        }
        nsView.refresh()
    }
}

final class TrafficLightLayoutNSView: NSView {
    var onMetricsChange: ((CGFloat, CGFloat) -> Void)?

    override var intrinsicContentSize: NSSize {
        NSSize(width: max(68, bounds.width), height: AppWindowChromeMetrics.trafficLightRowHeight)
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
        let metrics = TrafficLightLayoutMetrics.measure(in: window)
        onMetricsChange?(metrics.leadingInset, metrics.iconOffsetY)
    }
}

private struct TrafficToolbarOffsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var trafficToolbarOffsetY: CGFloat {
        get { self[TrafficToolbarOffsetKey.self] }
        set { self[TrafficToolbarOffsetKey.self] = newValue }
    }
}

/// Reads traffic-light vertical center and applies a small offset to sibling toolbar icons.
struct TrafficToolbarAlignment: ViewModifier {
    @State private var offsetY: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background {
                TrafficLightOffsetReader(offsetY: $offsetY)
            }
            .offset(y: offsetY)
    }
}

private struct TrafficLightOffsetReader: NSViewRepresentable {
    @Binding var offsetY: CGFloat

    func makeNSView(context: Context) -> TrafficLightLayoutNSView {
        let view = TrafficLightLayoutNSView()
        view.onMetricsChange = { _, y in
            DispatchQueue.main.async {
                if abs(offsetY - y) > 0.25 {
                    offsetY = y
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: TrafficLightLayoutNSView, context: Context) {
        nsView.onMetricsChange = { _, y in
            DispatchQueue.main.async {
                if abs(offsetY - y) > 0.25 {
                    offsetY = y
                }
            }
        }
        nsView.refresh()
    }
}

extension View {
    func trafficToolbarAligned() -> some View {
        modifier(TrafficToolbarAlignment())
    }
}
