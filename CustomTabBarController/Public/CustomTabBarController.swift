import UIKit

@MainActor open class CustomTabBarController: UIViewController {
    
    // MARK: - Open Properties
    
    open var tabBarHeight: CGFloat {
        return 49.0
    }
    
    // MARK: - Public Properties
    
    public private (set) var tabBar: CustomTabBar = CustomTabBar()
    public private (set) var viewControllers: [UIViewController?] = []
    public var selectedIndex: Int? {
        get {
            return viewControllers.firstIndex(where: { viewController in
                if let viewController {
                    return children.contains(viewController)
                } else {
                    return false
                }
            })
        }
        set {
            guard let newValue, newValue >= 0, newValue < viewControllers.count else { return }
            guard newValue != selectedIndex else { return }
            guard let pendingViewController = viewControllers[newValue] else { return }
            
            show(pendingViewController, sender: self)
        }
    }
    
    public weak var delegate: CustomTabBarControllerDelegate?
    
    // MARK: - Open Methods
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.delegate = self
        
        additionalSafeAreaInsets.bottom = tabBarHeight
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let bottomInset = view.window?.safeAreaInsets.bottom ?? 0.0
        
        tabBar.bottomInset = bottomInset
        
        view.addSubview(tabBar)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: tabBarHeight + bottomInset)
        ])
    }
    
    open override func show(_ vc: UIViewController, sender: Any?) {
        guard let selectedIndex, let currentViewController = viewControllers[selectedIndex] else {
            
            for viewController in children {
                viewController.willMove(toParent: nil)
                viewController.view.removeFromSuperview()
                viewController.removeFromParent()
            }
            
            addChild(vc)
            view.insertSubview(vc.view, belowSubview: tabBar)
            vc.didMove(toParent: self)
            
            return
        }
        
        tabBar.isUserInteractionEnabled = false
        
        let transitionContext = CustomTabBarControllerTransitionContext(containerViewController: self, fromViewController: currentViewController, toViewController: vc)
        
        addChild(vc)
        
        if let customAnimator = delegate?.animationControllerForTransition {
            customAnimator.animateTransition(using: transitionContext)
        } else {
            let defaultAnimator = CustomTabBarControllerTransitionAnimator()
            defaultAnimator.animateTransition(using: transitionContext)
        }
    }
    
    // MARK: - Public Methods
    
    public func setViewControllers(_ viewControllers: [UIViewController?]) {
        guard self.viewControllers.isEmpty else { return }
        guard !viewControllers.isEmpty else { return }
        
        for index in viewControllers.indices {
            viewControllers[index]?.view.tag = index
            viewControllers[index]?.view.frame = view.frame
        }
        
        self.viewControllers = viewControllers
        
        tabBar.setTabs(numberOfTabs: self.viewControllers.count)
        
        guard let firstViewControllerIndex = self.viewControllers.firstIndex(where: { $0 != nil }) else { return }
        
        selectedIndex = firstViewControllerIndex
    }
    
    public func setTabImage(_ image: UIImage?, forIndex index: Int) {
        tabBar.setImage(image, forTab: index, state: .normal)
    }
    
    public func setSelectedTabImage(_ image: UIImage?, forIndex index: Int) {
        tabBar.setImage(image, forTab: index, state: .selected)
    }
}

@MainActor @objc public protocol CustomTabBarControllerDelegate: NSObjectProtocol {
    
    @objc optional var animationControllerForTransition: UIViewControllerAnimatedTransitioning { get }
}

extension CustomTabBarController: CustomTabBarDelegate {
    
    open func tabBar(_ tabBar: CustomTabBar, shouldSelect index: Int) -> Bool {
        return true
    }
    
    open func tabBar(_ tabBar: CustomTabBar, didSelect index: Int) {
        
        if viewControllers[index] != nil {
            selectedIndex = index
        }
    }
}

extension UIViewController {
    
    public var customTabBarController: CustomTabBarController? {
        
        var parent = parent
        
        while parent != nil {
            if parent is CustomTabBarController {
                return parent as? CustomTabBarController
            }
            parent = parent?.parent
        }
        
        return nil
    }
}
