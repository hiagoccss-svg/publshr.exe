import SwiftUI
import WebKit

/// Hosts bundled web UI (tldraw whiteboard) inside the macOS IDE — same Supabase project as Electron.
struct MacWebModuleHost: NSViewRepresentable {
    let config: MacWebModuleConfig
    var onLoadError: ((String) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(config: config, onLoadError: onLoadError)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webConfig = WKWebViewConfiguration()
        webConfig.userContentController.add(context.coordinator, name: "publshr")
        let script = context.coordinator.injectionScript()
        webConfig.userContentController.addUserScript(
            WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        let webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        context.coordinator.load(into: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastConfig != config {
            context.coordinator.config = config
            context.coordinator.load(into: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var config: MacWebModuleConfig
        var onLoadError: ((String) -> Void)?
        weak var webView: WKWebView?
        var lastConfig: MacWebModuleConfig?

        init(config: MacWebModuleConfig, onLoadError: ((String) -> Void)?) {
            self.config = config
            self.onLoadError = onLoadError
            self.lastConfig = config
        }

        func injectionScript() -> String {
            let token = config.accessToken ?? ""
            let space = config.spaceId?.uuidString ?? ""
            let board = config.whiteboardId?.uuidString ?? ""
            let workspace = config.workspaceId?.uuidString ?? ""
            let user = config.userId?.uuidString ?? ""
            let url = config.supabaseURL
            let key = config.supabaseAnonKey
            return """
            window.__PUBLSHR_MAC_IDE__ = true;
            window.__PUBLSHR__ = {
              supabaseUrl: \(jsonString(url)),
              supabaseAnonKey: \(jsonString(key)),
              accessToken: \(jsonString(token)),
              spaceId: \(jsonString(space)),
              whiteboardId: \(jsonString(board)),
              workspaceId: \(jsonString(workspace)),
              userId: \(jsonString(user))
            };
            """
        }

        func load(into webView: WKWebView) {
            lastConfig = config
            guard let pageURL = MacWebModuleLoader.whiteboardPageURL(config: config) else {
                onLoadError?("Whiteboard bundle missing. Run: mac/publshr/scripts/bundle-web-modules-into-mac.sh")
                return
            }
            webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent())
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Reserved for future Swift ↔ JS bridge callbacks.
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadError?(error.localizedDescription)
        }

        private func jsonString(_ value: String) -> String {
            guard let data = try? JSONEncoder().encode(value),
                  let s = String(data: data, encoding: .utf8) else { return "\"\"" }
            return s
        }
    }
}
