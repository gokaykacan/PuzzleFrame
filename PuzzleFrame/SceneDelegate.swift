import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        let mainViewController = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainViewController)
        navigationController.isNavigationBarHidden = true
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        MemoryManager.shared.releaseMemory()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        MemoryManager.shared.prepareForForeground()
    }
    
    func sceneDidReceiveMemoryWarning(_ scene: UIScene) {
        MemoryManager.shared.handleMemoryWarning()
    }
}