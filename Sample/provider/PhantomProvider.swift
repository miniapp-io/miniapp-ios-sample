// Copyright © 2017-2022 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import WebKit
import MiniAppX
import UIKit

public class PhantomProvider: UIViewController, Provider {

    weak var webView: WKWebView?
    
    private class dummy {}
    
    let scriptHandlerName = "PhantomRpcProvider"

    public func providerJsUrl(jsFile: String) -> URL {
#if COCOAPODS
        let bundle = Bundle(for: PhantomProvider.dummy.self)
        let bundleURL = bundle.resourceURL?.appendingPathComponent("WalletBridgeProvider.bundle")
        let resourceBundle = Bundle(url: bundleURL!)!
        return resourceBundle.url(forResource: jsFile, withExtension: "js")!
#else
        return Bundle.main.url(forResource: jsFile, withExtension: "js")!
#endif
    }

    public func providerScript(jsFile: String)-> WKUserScript {
        let source = try! String(contentsOf: providerJsUrl(jsFile: jsFile))
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    public var injectScript: WKUserScript {
        let source = """
        (function() {
            window.PhantomRpcProvider = {
                onDeepLinkMessage: function(data) {
                    webkit.messageHandlers.PhantomRpcProvider.postMessage(data);
                }
            };
            if (typeof window !== 'undefined') {
                window.PhantomRpcProvider = window.PhantomRpcProvider;
            }
        })();
        """
        return WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
    
    public func inject(webView: WKWebView) {
        self.webView = webView
        let contentController = webView.configuration.userContentController
        contentController.addUserScript(self.providerScript(jsFile: "phantom_solana"))
        contentController.addUserScript(self.providerScript(jsFile: "phantom_sdk_inject"))
        contentController.addUserScript(self.injectScript)
        contentController.removeScriptMessageHandler(forName: self.scriptHandlerName)
        contentController.add(self, name: self.scriptHandlerName)
    }
    public func handleDeepLink(url: URL) {  
        let jsonString = "{\"uri\": \"\(url.absoluteString)\"}"
        let jsCode = """
        (function() {
            try {
                // 直接发送 JSON 字符串，让 phantom_solana.js 进行 JSON.parse
                window.dispatchEvent(new CustomEvent('deeplinkRpcMessage', {
                    detail: '\(jsonString)'
                }));
            } catch(e) {
                console.error('Phantom RPC 事件发送失败:', e);
            }
        })();
        """
        
        self.webView?.evaluateJavaScript(jsCode)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhantomProvider: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let json = message.json
        print(json)
        
        guard let rpcRequestid = json["id"] as? String, let urlString = json["uri"] as? String else {
            return
        }

        WalletBridgeProvider.getInstance().providerMap[rpcRequestid] = self

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            print("Invalid URL: \(urlString)")
        }
    }
}
