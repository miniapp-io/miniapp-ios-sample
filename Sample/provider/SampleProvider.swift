import Foundation
import WebKit
import MiniAppX
import UIKit

public class SampleProvider: UIViewController, Provider {
    
    weak var webView: WKWebView?
    
    let scriptHandlerName = "SampleRpc"
    
    private var injectScript: WKUserScript {
        let source = """
        (function() {
            window.DeJoyRpc = {
                dismiss: function() {
                    webkit.messageHandlers.SampleRpc.postMessage({method: 'dismiss'});
                }
            };
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
    
    public func inject(webView: WKWebView) {
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.addUserScript(self.injectScript)
        contentController.removeScriptMessageHandler(forName: self.scriptHandlerName)
        contentController.add(self, name: self.scriptHandlerName)
    }
    
    public func handleDeepLink(url: URL) {
        
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SampleProvider: WKScriptMessageHandler {
    
    private func dismiss() {
        if let v = self.webView {
            MiniSDKManager.shared.miniAppService.getMiniAppByWebView(v)?.requestDismiss(true, true)
        }
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        guard let body = message.body as? [String: Any],
              let method = body["method"] as? String else {
            return
        }
        
        switch method {
        case "dismiss":
            dismiss()
        default:
            break
        }
    }
}
