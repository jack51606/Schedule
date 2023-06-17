import UIKit

open class CustomNavigationChildViewController: UIViewController {
    
    // MARK: - Public Properties
    
    public var navigationBar: UINavigationBar = {
        let navigationBar = UINavigationBar()
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        return navigationBar
    }()
    public let customNavigationItem = UINavigationItem()
    
    // MARK: - Private Properties
    
    private var navigationBarTopConstraint: NSLayoutConstraint!
    
    // MARK: - Life Cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        additionalSafeAreaInsets.top = navigationBar.intrinsicContentSize.height
        
        navigationBar.setItems([customNavigationItem], animated: false)
        
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBarTopConstraint = navigationBar.topAnchor.constraint(equalTo: view.topAnchor)
        if let parent = parent as? CustomNavigationController, !parent.isPresentedModally, let parentTopInset = parent.view.window?.safeAreaInsets.top {
            navigationBarTopConstraint.constant = parentTopInset
        }
        NSLayoutConstraint.activate([
            navigationBarTopConstraint,
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.bringSubviewToFront(navigationBar)
    }
}
