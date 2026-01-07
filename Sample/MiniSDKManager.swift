//
//  MiniSDKManager.swift
//  Sample2
//
//  Created by ow3bili on 2024/8/22.
//

import UIKit
import MiniAppX

enum AppType : String {
    case MINIAPP
    case WEBPAGE
}

@objcMembers
class MiniSDKManager: NSObject, IAppDelegate, BridgeProviderFactory {
    
    let walletProvider = WalletBridgeProvider()
    
    func buildBridgeProvider(id: String?, type: String, url: String?) -> (any MiniAppX.BridgeProvider)? {
        return walletProvider
    }
    
    
    let SHORTCUT_LINK = "miniappx_link"
    let SHORTCUT_TYPE = "miniappx_type"
    
    let APP_ID_WALLET = "9"
    let APP_ID_MARKETPLACE = "10"
    let APP_ID_APPMASTER = "2lv8dp7JjF2AU0iEk2rMYUaySjU"

    static let shared = MiniSDKManager()
    
    var openPlatformPlugin: OpenPlatformPlugin
    
    var miniAppService: MiniAppService
    
    var isAuth: Bool = false
    
    private var shortcutItem: UIApplicationShortcutItem? = nil
    
    
    let idToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImhrOTV2M3p6YjdjczltNHJlYXN3dXl6aHRoemFkZ3cxczh0eTRjbjYiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjUzNTIzMjc0ODAsImlhdCI6MTc1MjMyNzQ4MCwic3ViIjoidGVzdCIsInVzZXJfaWQiOiJ0ZXN0IiwidXNlcm5hbWUiOiJ0ZXN0In0.Kv82MMZp-QvWnPxHwPFWy0RnJ36AepIYqqaX9S64ABYLnIHk51mXDypTEd5dMUc5kp_UT1H9NxTTArXxsJCRBl84zp2-vN4cswXixVcZj4f_moadTQQvBEnZ52VUh-xIbFMSPFrIjsbDxIsBMUYl5DAMvhr2swnCswdzm5x6qTHoxuqCEZMX0CwJvZZbbMU3w5uwZ2CmoAa27TURdxH0_7UqVGfojrQhTfEld5vfgZztWTQUHZY0t6WmZ1rwOXEJuqaePX3kyhfytECFlx6Nd2xwNw2DHOhDGFEM47AVv8J7riFF3etrkVkhHSz5JXyIhfG7PSldHgdvbRk1qtDGfA"
    
    private override init() {
        self.openPlatformPlugin = PluginsManager.getInstance().getPlugin(PluginName.openPlatform.rawValue)!
        self.miniAppService = openPlatformPlugin.getMiniAppService()!
    }
    
    private func tokenProvider() async -> String? {
        return await withCheckedContinuation { [weak self] continuation in
            guard let strongSelf = self else {
                return
            }
            continuation.resume(returning: strongSelf.idToken)
        }
    }
    
    private func preloadApp() {
        [APP_ID_MARKETPLACE,APP_ID_WALLET,APP_ID_APPMASTER].forEach { id in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                let config = try? WebAppPreloadParameters.Builder()
                    .miniAppId(id)
                    .build()
                if let config = config {
                    self?.miniAppService.preload(config: config)
                }
            }
        }
    }
    
    func signIn() {
        self.openPlatformPlugin.signIn(
            verifier: "3611ba4b-9a1a-4ac0-97eb-9a5fa5b60ec5",
            isDev: false,
            apiHost: "https://api.m.openweb3.io",
            idTokenProvider: tokenProvider,
            onVerifierSuccess: { [weak self] in
                // Do something
                self?.isAuth = true
                self?.preloadApp()
                self?.progressOnAuth()
            },
            onVerifierFailure: { code, message in
                print("Verifier Err, code= \(code), message: \(String(describing: message))")
            })
    }
    
    func setupMiniAppService() {
        if let window = UIApplication.shared.windows.first {
            
            let appConfig = AppConfig.Builder(appName: "Sample2",
                                              webAppName: "MiniAppX",
                                              mePath: ["https://miniappx.io","https://t.me"],
                                              window: window,
                                              appDelegate: MiniSDKManager.shared)
                .languageCode("zh")
                .userInterfaceStyle(.light)
                .maxCachePage(5)
                .bridgeProviderFactory(self)
                .resourceProvider(nil)
                .floatWindowSize(width: 90.0, height: 159.0)
                .privacyUrl("https://docs.openweb3.io/docs/standard-miniapp-privacy-policy")
                .termsOfServiceUrl("https://docs.openweb3.io/docs/terms-of-service-for-mini-apps")
                .build()
            
            miniAppService.setup(config: appConfig) {
                self.signIn()
            }
        }
    }
    
    private func progressOnAuth() {
        if let shortcutItem = self.shortcutItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let _ = self.handleShortcutItem(shortcutItem)
                self.shortcutItem = nil
            }
        }
    }
    
    func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        
        guard let userInfo = shortcutItem.userInfo as? [String: String] else {
            return false
        }
        
        if !isAuth {
            self.shortcutItem = shortcutItem
            return true
        }
        
        if let type = userInfo[SHORTCUT_TYPE], let link = userInfo[SHORTCUT_LINK] {
            navigateToScreen(link: link, type: type)
            return true
        }
        
        return false
    }
    
    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No active window or rootViewController found")
            return nil
        }
    
        var topViewController = rootViewController
        while let presentedVC = topViewController.presentedViewController {
            topViewController = presentedVC
        }
        
        return topViewController
    }
    
    func navigateToScreen(link: String, type: String) {
        if let vc = getTopViewController() {
            let _ = self.launchWithUrl(vc: vc, url: link, type: type)
        }
    }
    
    func launch(config: WebAppLaunchParameters) -> IMiniApp? {
        return miniAppService.launch(config: config)
    }
    
    func launchWithUrl(vc: UIViewController, url: String, type: String = AppType.MINIAPP.rawValue)  {
        
        if false == url.starts(with: "https://") {
            return
        }
        
        if type == AppType.MINIAPP.rawValue {
            do{
                let config = try WebAppLaunchWithDialogParameters.Builder()
                    .parentVC(vc)
                    .url(url)
                    .build()
                
              let _ = miniAppService.launch(config: config)
                
            }
            catch {
                print("An error occurred: \(error)")
            }
        } else {
            do{
                let config = try DAppLaunchParameters.Builder()
                    .parentVC(vc)
                    .url(url)
                    .build()
                
                let _ = miniAppService.launch(config: config)
                
            }
            catch {
                print("An error occurred: \(error)")
            }
        }
    }
    
    var customMethodProvider: (IMiniApp, String, String?, @escaping (String?) -> Void )-> Bool = { _, method, params, callback in
        if(method == "getRoomConfig") {
            // TODO Return current tribe to add to App IDs
            callback("{\"miniapps\": [\"10\"]}")
            return true
        }
        if(method == "updateRoomConfig") {
            // 1. TODO Update apps to tribe
            callback(nil)
            return true
        }
        callback("TODO: To implement Custom Method in AppDelegate, Method called: \(method)")
        return false
    }
    
    var qrcodeProvider: (IMiniApp, String?, @escaping (String?) -> Void) -> UINavigationController? = { _, desc, callback in
        callback("TODO: To implement in AppDelegate")
        return nil
    }
    
    var attachActionProvider: (IMiniApp, String?, String)-> Void =  { _,action,payload in
            
    }
    
    var schemeProvider: (IMiniApp, String) async -> Bool = { _,_ in
        return false
    }
    
    /**
     * Open a new session within the APP
     * @param query String
     * @param types List<String>
     */
    func switchInlineQuery(app: IMiniApp, query: String, types: [String]) async -> Bool {
        return false
    }
    
    /**
     Share links or text.
     
     - Parameters:
        - linkOrText: Share links or text.
    */
    func shareLinkOrText(linkOrText: String) {
        
    }
    
    /**
     Share link  and  text.
     
     - Parameters:
        - link: Share link
        - text: Sare text.
    */
    func shareLink(link: String?, text: String?) {
        
    }
    
    /**
     * Check if the current session supports and is authorized for messaging functionality
     * @return Boolean
     */
    func checkPeerMessageAccess(app: IMiniApp) async -> Bool {
        return false
    }
    
    /**
     * Request authorization for sending messages in the current session
     * @return Boolean
     */
    func requestPeerMessageAccess(app: IMiniApp) async -> Bool {
        return false
    }
    
    /**
     * Send message to current session
     * @param content String?
     * @return Boolean
     */
    func sendMessageToPeer(app: IMiniApp, content: String?) -> Bool {
        return true
    }
    
    /**
     * Request to send phone number to current session
     * @return Boolean
     */
    func requestPhoneNumberToPeer(app: IMiniApp) async -> Bool {
        return false
    }
    
    /**
     * Get biometric authentication information, including (APP certificate authorization, face, fingerprint, etc.)
     * @return BiometryInfo?
     */
    func canUseBiometryAuth(app: IMiniApp) ->  Bool {
        return true
    }
    
    /**
     * Request to update biometric authentication
     * @param token String?
     * @param reason String?
     * @return Pair<Boolean,String?> [(false,null): Failed, no biometric authentication authorized, (true, null): Update failed, old token has been deleted, (true, token value): Update successful]
     */
    func updateBiometryToken(app: IMiniApp, token: String?, reason: String?) async -> (Bool,String?) {
        return (false, nil)
    }
    
    /**
     * Open biometric authentication settings
     */
    func openBiometrySettings(app: IMiniApp) async -> Void {
        
    }
    
    /**
     * Api Error
     */
    func onApiError(error: ApiError) {
        switch(error) {
        case .authInvalid:
            signIn()
        case .requestFailed(let code, let message):
            if code == 401 {
                signIn()
            }
        default:
            break
        }
    }
    
    func onMinimization(app: any MiniAppX.IMiniApp) {
        
    }
    
    func onMaximize(app: any MiniAppX.IMiniApp) {
        
    }
    
    func onMoreButtonClick(app: any MiniAppX.IMiniApp, menus: [String]) -> Bool {
        return false
    }
    
    func onClickMenu(app: any MiniAppX.IMiniApp, type: String) {
        if type == "FEEDBACK" {
            if let miniAppVc = app.getVC() {
                let chatViewController = ChatViewController()
                miniAppVc.present(chatViewController, animated: true)
            }
        } else if type == "SHARE" {
            Task {
                let shareInfo = await app.getShareInfo()
                guard let title = shareInfo?.title else {
                    return
                }
            }
        } else if type == "SHORTCUT" {
            // TODO
        }
    }

}
