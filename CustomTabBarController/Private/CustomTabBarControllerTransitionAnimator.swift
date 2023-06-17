import UIKit

internal final class CustomTabBarControllerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - Private Properties
    
    private let duration: TimeInterval = 0.16
    
    private enum Direction {
        case left, right
    }
    
    // MARK: - Public Methods
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        let fromView = transitionContext.view(forKey: .from)!
        let toView = transitionContext.view(forKey: .to)!
        
        let direction: Direction = fromView.tag < toView.tag ? .right : .left
        
        containerView.insertSubview(toView, at: 1)
        
        let offset = fromView.frame.width / 4
        let fromViewTransform = CGAffineTransform(translationX: direction == .right ? -offset : offset, y: 0)
        let toViewTransform = CGAffineTransform(translationX: direction == .right ? offset : -offset, y: 0)
        
        toView.alpha = 0
        toView.transform = toViewTransform
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            
            fromView.alpha = 0
            fromView.transform = fromViewTransform
            
            toView.alpha = 1
            toView.transform = CGAffineTransformIdentity
            
        } completion: { _ in
            
            fromView.alpha = 1
            toView.alpha = 1
            fromView.transform = CGAffineTransformIdentity
            toView.transform = CGAffineTransformIdentity
            
            let isCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!isCancelled)
        }
    }
}
