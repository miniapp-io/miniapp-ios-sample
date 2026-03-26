// Copyright © 2017-2022 Trust Wallet.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import WebKit
import MiniAppX

class WalletBridgeProvider : BridgeProvider {
    
    private let deepLinkHost = "miniappx.io"
    
    static let shared = WalletBridgeProvider()

    static func getInstance() -> WalletBridgeProvider {
        return shared
    }

    public var providerMap: [String: Provider] = [:]

    public func handleDeepLink(url: URL) {
        if url.host == deepLinkHost {
            if url.pathComponents.count >= 3 {
                let rpcRequestId = url.pathComponents[2]
                let provider = providerMap[rpcRequestId]
                provider?.handleDeepLink(url: url)
            }
        }
    }
    
    func shouldOverrideUrlLoading(url: URL) -> Bool {
        return false
    }
    
    var messageHandler: WKScriptMessageHandler?
    
    func onWebViewCreated(_ webView: WKWebView, parentVC: UIViewController) {
        inject(webView: webView)
    }
    
    func onWebViewDestroy(_ webView: WKWebView) {
    }
    
    func onWebPageLoaded(_ webView: WKWebView) {
        
    }
    
    var navigationDelegate: () -> (any WKNavigationDelegate)? = {
        return nil
    }
    
    var uIDelegate: () -> (any WKUIDelegate)? = {
        return nil
    }
    
    func inject(webView: WKWebView) {
        TrustWeb3Provider().inject(webView: webView)
        PhantomProvider().inject(webView: webView)
        SampleProvider().inject(webView: webView)
    }
}

protocol Provider {
    func inject(webView: WKWebView)
    func handleDeepLink(url: URL)
}
