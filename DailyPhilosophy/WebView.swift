import SwiftUI
import WebKit

/// Hosts the bundled index.html in a WKWebView and wires up the native bridge.
struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Bridge { Bridge() }

    func makeUIView(context: Context) -> WKWebView {
        let bridge = context.coordinator

        let controller = WKUserContentController()
        controller.addUserScript(Bridge.bootScript())
        controller.add(bridge, name: "dp")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 247 / 255, green: 244 / 255, blue: 238 / 255, alpha: 1)
        web.scrollView.backgroundColor = web.backgroundColor
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.bounces = true
        web.allowsLinkPreview = false
        if #available(iOS 16.4, *) { web.isInspectable = true }
        bridge.webView = web

        bridge.loadPage()
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Receives messages from the page: save state, manage the API key, ask the model.
final class Bridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    /// Hands saved state and key status to the page before any of its script runs.
    static func bootScript() -> WKUserScript {
        let state = Store.loadJSON() ?? "null"
        let hasKey = Keychain.get() != nil
        let js = "window.__nativeState = \(state); window.__nativeHasKey = \(hasKey ? "true" : "false");"
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    func loadPage() {
        guard let web = webView else { return }
        if let url = Updater.activeURL() {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            web.loadHTMLString("<h1>index.html is missing from the app bundle.</h1>", baseURL: nil)
        }
    }

    private func reloadPage() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let web = self.webView else { return }
            web.configuration.userContentController.removeAllUserScripts()
            web.configuration.userContentController.addUserScript(Bridge.bootScript())
            self.loadPage()
        }
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        switch type {
        case "save":
            if let json = body["state"] as? String { Store.saveJSON(json) }

        case "setKey":
            if let key = body["key"] as? String {
                let ok = Keychain.set(key.trimmingCharacters(in: .whitespacesAndNewlines))
                keyStatus(ok)
            }

        case "delKey":
            Keychain.delete()
            keyStatus(false)

        case "ask":
            guard let id = body["id"] as? String,
                  let system = body["system"] as? String,
                  let messages = body["messages"] as? [[String: Any]] else { return }
            let clean: [[String: String]] = messages.compactMap { m in
                guard let role = m["role"] as? String, let content = m["content"] as? String else { return nil }
                return ["role": role, "content": content]
            }
            Task {
                do {
                    let text = try await ClaudeClient.send(system: system, messages: clean)
                    self.reply(id: id, text: text, error: nil)
                } catch {
                    self.reply(id: id, text: nil, error: error.localizedDescription)
                }
            }

        case "update":
            Task {
                do {
                    try await Updater.fetch()
                    self.reloadPage()
                } catch {
                    self.run("window.__updateStatus && window.__updateStatus(\(Self.literal(error.localizedDescription)));")
                }
            }

        case "check":
            Task {
                if await Updater.updateAvailable() {
                    self.run("window.__updateAvailable && window.__updateAvailable();")
                }
            }

        case "resetContent":
            Updater.reset()
            reloadPage()

        default:
            break
        }
    }

    private func keyStatus(_ has: Bool) {
        run("window.__keyStatus && window.__keyStatus(\(has ? "true" : "false"));")
    }

    private func reply(id: String, text: String?, error: String?) {
        run("window.__reply(\(Self.literal(id)), \(Self.literal(text)), \(Self.literal(error)));")
    }

    private func run(_ js: String) {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    /// Encodes a string (or nil) as a JavaScript literal.
    private static func literal(_ value: String?) -> String {
        guard let value else { return "null" }
        if let data = try? JSONSerialization.data(withJSONObject: [value], options: []),
           let s = String(data: data, encoding: .utf8) {
            // s looks like ["..."]; strip the brackets.
            return String(s.dropFirst().dropLast())
        }
        return "null"
    }
}
