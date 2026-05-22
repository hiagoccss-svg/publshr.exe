import AppKit
import LiveKit
import SwiftUI

/// Renders a LiveKit `VideoTrack` in SwiftUI (macOS `VideoView`).
struct LiveKitVideoTrackView: NSViewRepresentable {
    let track: VideoTrack?
    var layoutMode: VideoView.LayoutMode = .fill

    func makeNSView(context: Context) -> VideoView {
        let view = VideoView()
        view.layoutMode = layoutMode
        view.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        return view
    }

    func updateNSView(_ nsView: VideoView, context: Context) {
        nsView.layoutMode = layoutMode
        nsView.track = track
    }
}
