import UIKit
import MiniAppX  
import WebKit

class ViewController: UIViewController {
    
    var chatViewController: ChatViewController?
    
    @IBOutlet weak var urlInputTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = "https://www.magiceden.io"
        
        urlInputTextView.text = url

        MiniSDKManager.shared.setupMiniAppService()
    }
    
    @IBAction func onTabLaunchWithUrl(_ sender: Any) {
        
        let url = urlInputTextView.text
        
        if false == url?.starts(with: "https://") {
            return
        }
        
        do{
            let config = try WebAppLaunchWithDialogParameters.Builder()
                .parentVC(self)
                .url(url)
                .build()
            
            let _ = MiniSDKManager.shared.miniAppService.launch(config: config)
        }
        catch {
            print("An error occurred: \(error)")
        }

    }
    
    @IBAction func onTabLaunchDApp(_ sender: Any) {
        let url = urlInputTextView.text
        
        if false == url?.starts(with: "https://") {
            return
        }
        
        do{
            
            let config = try DAppLaunchParameters.Builder()
                .parentVC(self)
                .url(url)
                .build()
            
            let _ = MiniSDKManager.shared.miniAppService.launch(config: config)
        }
        catch {
            print("An error occurred: \(error)")
        }
    }
    
    @IBAction func onTabLaunchLocalDemo(_ sender: Any) {
        
        do{
            let config = try WebAppLaunchWithDialogParameters.Builder()
                .parentVC(self)
                .botName("mini")
                .miniAppName("mini")
                .autoExpand(false)
                .useCache(false)
                .isLocalSource(true)
                .build()
            
            let minApp = MiniSDKManager.shared.miniAppService.launch(config: config)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                if let miniAppVc = minApp?.getVC() {
                    weakSelf.chatViewController = ChatViewController()
                    miniAppVc.navigationController?.pushViewController(weakSelf.chatViewController!, animated: true)
                }
            }
        }
        catch {
            print("An error occurred: \(error)")
        }
    }
    
    @IBAction func onTabLaunchOnChat(_ sender: Any) {
        chatViewController = ChatViewController()
        self.navigationController?.pushViewController(chatViewController!, animated: true)
    }
    
    @IBAction func onTabLaunchMarketPlace(_ sender: Any) {

        do{
            
            var components = URLComponents()

            components.queryItems = [
                URLQueryItem(name: "roomId", value: "1"),
                URLQueryItem(name: "roomName", value: "Test Tribe"),
                URLQueryItem(name: "roomAvatar", value: "https://thumb.ac-illust.com/78/782445b4704adca448601a89d4b80f7c_w.jpeg"),
            ]
            
            
            let config = try WebAppLaunchWithDialogParameters.Builder()
                .parentVC(self)
//                .url("https://game.bt.qiku.net/games/fruittri?code=LuLT2PdXscbH3TOmTpX+LVnPClMHSZFa66v7ygw40CExOCQXfkUaBZzEeM+hoOtW&channel=telegram&lan=zh-hans")
                .miniAppId("10")
                .useCache(false)
                .params(["spaceId":"11111", "appId":"10"])
                .startParams(components.query)
                .build()
            
            MiniSDKManager.shared.miniAppService.launch(config: config)
        }
        catch {
            print("An error occurred: \(error)")
        }
    }
    
    @IBAction func onTabLaunchAppMarster(_ sender: Any) {
        
        do{
            
            let config = try WebAppLaunchWithDialogParameters.Builder()
                .parentVC(self)
                .url("https://miniappx.io/apps/2lv8dp7JjF2AU0iEk2rMYUaySjU?roomId=2222")
                .build()
            
            MiniSDKManager.shared.miniAppService.launch(config: config)
        }
        catch {
            print("An error occurred: \(error)")
        }
    }
}
