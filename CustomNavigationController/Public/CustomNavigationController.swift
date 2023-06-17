import UIKit

@MainActor open class CustomNavigationController: UINavigationController {
    
    public var isPresentedModally: Bool = false
    
    // MARK: - Private Properties
    
    private var transitionAnimator = CustomNavigationControllerTransitionAnimator()
    private var transitionAnimationFractionComplete: CGFloat = 0.0
    
    private let swipeBackGestureRecognizer = UIPanGestureRecognizer()
    
    // MARK: - Life Cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        isNavigationBarHidden = true
        
        setSwipeBackGestureRecognizer()
    }
    
    // MARK: - Private Methods
    
    private func setSwipeBackGestureRecognizer() {
        
        swipeBackGestureRecognizer.addTarget(self, action: #selector(handleSwipeBackGesture))
        swipeBackGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeBackGestureRecognizer)
    }
    
    @objc private func handleSwipeBackGesture(_ gesture: UIPanGestureRecognizer) {
        guard let animator = transitionAnimator.animator else { return }
        
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x
        
        let operation: UINavigationController.Operation = translation < 0 ? .push : .pop
        
        let percent = abs(translation) > view.frame.width ? 1.0 : abs(translation) / view.frame.width
        
        switch gesture.state {
            
        case .began:
            popViewController(animated: true)
        case .changed:
            if animator.isRunning {
                animator.pauseAnimation()
                transitionAnimationFractionComplete = animator.fractionComplete
            } else if animator.state == .active {
                animator.fractionComplete = operation == transitionAnimator.operation ? transitionAnimationFractionComplete + percent : transitionAnimationFractionComplete - percent
            }
        case .cancelled, .ended:
            if animator.state == .active {
                animator.isReversed = !(animator.fractionComplete > 0.3 || velocity > 160)
                
                let initialVelocity = CGVector(dx: abs(velocity) / (view.frame.width * (1 - animator.fractionComplete)), dy: 0)
                if translation > 0 {
                    animator.continueAnimation(withTimingParameters: UISpringTimingParameters(dampingRatio: 1, initialVelocity: initialVelocity), durationFactor: 0)
                } else {
                    animator.stopAnimation(false)
                    animator.finishAnimation(at: .start)
                }
            }
        default:
            break
        }
    }
}

extension CustomNavigationController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        transitionAnimator.operation = operation
        
        return transitionAnimator
    }
    
    open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {}
    
    open func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {}
}

extension CustomNavigationController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        guard let currentViewController, let rootViewController, currentViewController != rootViewController else { return false }
        guard let translation = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: view).x else { return false }
        
        return transitionAnimator.animator.state != .active && translation > 0
    }
}

extension UINavigationController {
    
    public var rootViewController: UIViewController? {
        return viewControllers.count > 0 ? viewControllers.first : nil
    }
    
    public var currentViewController: UIViewController? {
        return viewControllers.count > 0 ? topViewController : nil
    }
}
