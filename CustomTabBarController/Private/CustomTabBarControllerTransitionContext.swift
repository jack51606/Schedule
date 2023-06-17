import UIKit

internal final class CustomTabBarControllerTransitionContext: NSObject, UIViewControllerContextTransitioning {
    
    public var containerView: UIView {
        return _containerViewController.view
    }
    
    public private (set) var isAnimated: Bool = false
    
    public private (set) var isInteractive: Bool = false
    
    public private (set) var transitionWasCancelled: Bool = false
    
    public private (set) var presentationStyle: UIModalPresentationStyle = .automatic
    
    public var targetTransform: CGAffineTransform = CGAffineTransformIdentity
    
    private unowned var _containerViewController: CustomTabBarController
    private unowned var _fromViewController: UIViewController
    private unowned var _toViewController: UIViewController
    
    public init(containerViewController: CustomTabBarController, fromViewController: UIViewController, toViewController: UIViewController) {
        
        _containerViewController = containerViewController
        _fromViewController = fromViewController
        _toViewController = toViewController
    }
    
    public func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    
    public func finishInteractiveTransition() {}
    
    public func cancelInteractiveTransition() {}
    
    public func pauseInteractiveTransition() {}
    
    public func completeTransition(_ didComplete: Bool) {
        
        _toViewController.didMove(toParent: _containerViewController)
        
        _fromViewController.willMove(toParent: nil)
        _fromViewController.view.removeFromSuperview()
        _fromViewController.removeFromParent()
        
        _containerViewController.tabBar.isUserInteractionEnabled = true
    }
    
    public func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case .from:
            return _fromViewController
        case .to:
            return _toViewController
        default:
            return nil
        }
    }
    
    public func view(forKey key: UITransitionContextViewKey) -> UIView? {
        switch key {
        case .from:
            return _fromViewController.view
        case .to:
            return _toViewController.view
        default:
            return nil
        }
    }
    
    public func initialFrame(for vc: UIViewController) -> CGRect {
        return vc.view.frame
    }
    
    public func finalFrame(for vc: UIViewController) -> CGRect {
        return vc.view.frame
    }
}
