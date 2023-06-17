import UIKit
import CustomTabBarController
import CustomNavigationController

final class Page: CustomNavigationController {
    
    override func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        super.navigationController(navigationController, willShow: viewController, animated: animated)
        
        guard let mainController = parent as? CustomTabBarController else { return }
        guard let rootViewController = navigationController.rootViewController else { return }
        
        if viewController != rootViewController {
            mainController.tabBar.isUserInteractionEnabled = false
        }
        
        viewController.transitionCoordinator?.animate(alongsideTransition: { context in
            
            mainController.tabBar.alpha = viewController == rootViewController ? 1 : 0
            mainController.additionalSafeAreaInsets.bottom = viewController == rootViewController ? mainController.tabBarHeight : 0
            
        }) { [weak self] context in
            guard let self else { return }
            
            mainController.additionalSafeAreaInsets.bottom = currentViewController == rootViewController ? mainController.tabBarHeight : 0
        }
    }
    
    override func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        super.navigationController(navigationController, didShow: viewController, animated: animated)
        
        guard let mainController = parent as? CustomTabBarController else { return }
        guard let rootViewController = navigationController.rootViewController else { return }
        
        if viewController == rootViewController {
            mainController.tabBar.isUserInteractionEnabled = true
        }
    }
}
