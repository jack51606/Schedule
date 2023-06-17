import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    private let appearanceManager = AppearanceManager.shared
    private let themeColorManager = ThemeColorManager.shared
    private let defaults = UserDefaults.standard
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainController()
        window.makeKeyAndVisible()
        self.window = window
        
        window.overrideUserInterfaceStyle = appearanceManager.currentAppearance
        window.tintColor = themeColorManager.currentThemeColor
        
        setObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath else { return }
        
        switch keyPath {
        case Constants.UserDefaultsKeys.appearance:
            guard let window else { return }
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve) { [weak self] in
                guard let self else { return }
                window.overrideUserInterfaceStyle = appearanceManager.currentAppearance
            }
        case Constants.UserDefaultsKeys.themeColor:
            guard let window else { return }
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) { [weak self] in
                guard let self else { return }
                window.tintColor = themeColorManager.currentThemeColor
            }
        default:
            break
        }
    }
    
    private func setObservers() {
        defaults.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance, context: nil)
        defaults.addObserver(self, forKeyPath: Constants.UserDefaultsKeys.themeColor, context: nil)
    }
    
    private func removeObservers() {
        defaults.removeObserver(self, forKeyPath: Constants.UserDefaultsKeys.appearance)
        defaults.removeObserver(self, forKeyPath: Constants.UserDefaultsKeys.themeColor)
    }
}
