import UIKit
import WebKit

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0)

        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "haptic")
        
        // Native Haptic and Viewport Script Injection
        let scriptSource = """
        (function() {
            // Polyfill navigator.vibrate to native iOS Taptic Engine
            if (!navigator.vibrate || window.webkit) {
                navigator.vibrate = function(pattern) {
                    try {
                        var style = 'light';
                        if (Array.isArray(pattern)) {
                            style = pattern.length > 2 ? 'heavy' : 'medium';
                        } else if (typeof pattern === 'number' && pattern > 60) {
                            style = 'medium';
                        }
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.haptic) {
                            window.webkit.messageHandlers.haptic.postMessage(style);
                        }
                    } catch(e) {}
                };
            }
        })();
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        config.userContentController = userContentController

        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = true
        webView.navigationDelegate = self
        webView.uiDelegate = self

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loadLocalApp()
    }

    func loadLocalApp() {
        if let wwwURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "www") {
            webView.loadFileURL(wwwURL, allowingReadAccessTo: Bundle.main.bundleURL)
        } else if let directURL = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(directURL, allowingReadAccessTo: Bundle.main.bundleURL)
        } else {
            print("[Ulgen iOS] Could not find local index.html in bundle.")
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "haptic" {
            guard let style = message.body as? String else { return }
            DispatchQueue.main.async {
                switch style {
                case "heavy":
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                case "medium":
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                case "success":
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                case "error":
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                default:
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
