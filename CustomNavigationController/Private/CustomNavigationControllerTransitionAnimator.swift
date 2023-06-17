import UIKit

internal final class CustomNavigationControllerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - Public Properties
    
    public var operation: UINavigationController.Operation = .none
    public private (set) var animator: UIViewPropertyAnimator!
    
    // MARK: - Private Properties
    
    private let duration: TimeInterval = 0.5
    
    // MARK: - Public Methods
    
    public override init() {
        animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1)
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return duration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else { return }
        guard let toView = transitionContext.view(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        
        if operation == .push {
            containerView.insertSubview(toView, aboveSubview: fromView)
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)
        }
        
        let offset = containerView.frame.width
        let fromViewTransform = CGAffineTransform(translationX: operation == .push ? -offset : offset, y: 0)
        let toViewTransform = CGAffineTransform(translationX: operation == .push ? offset : -offset, y: 0)
        
        toView.transform = toViewTransform
        
        animator.addAnimations {
            
            fromView.transform = fromViewTransform
            toView.transform = CGAffineTransformIdentity
        }
        
        animator.addCompletion { [weak self] position in
            guard let self else { return }
            
            fromView.transform = CGAffineTransformIdentity
            toView.transform = CGAffineTransformIdentity
            
            if position == .end {
                operation = .none
            }
            
            transitionContext.completeTransition(position == .end)
        }
        
        animator.startAnimation()
    }
}
