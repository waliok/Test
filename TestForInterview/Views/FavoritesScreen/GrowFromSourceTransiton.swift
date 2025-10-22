//
//  Custom.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 22/10/2025.
//

import UIKit
// MARK: - Custom Transition: Grow-from-Source Animation
//
// Presents the Favorites screen by scaling it up from the Favorites button’s position.
// The transition uses a spring-based scale transform (0.02 → 1.0) and centers
// around the button’s midpoint for a smooth "expanding modal" effect.
// On dismissal, the view shrinks back into the button with matching spring dynamics.

final class FavoritesPresentationController: UIPresentationController {
    private let blurView = UIVisualEffectView(effect: nil)
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        blurView.addGestureRecognizer(tap)
    }
    
    @objc private func dismissSelf() { presentedViewController.dismiss(animated: true) }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView?.bounds ?? .zero
    }
    
    override func presentationTransitionWillBegin() {
        guard let cv = containerView else { return }
        blurView.frame = cv.bounds
        cv.insertSubview(blurView, at: 0)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = UIBlurEffect(style: .systemMaterialDark)
        })
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.blurView.effect = nil
        }, completion: { _ in
            self.blurView.removeFromSuperview()
        })
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
        blurView.frame = containerView?.bounds ?? .zero
    }
}

// MARK: - Grow Animator

final class FavoritesGrowAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private let originFrame: CGRect
    init(isPresenting: Bool, originFrame: CGRect) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting ? 0.65 : 0.55
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        // Translate origin (window coords) to container coords
        let originInContainer = container.convert(originFrame, from: nil)
        let originCenter = CGPoint(x: originInContainer.midX, y: originInContainer.midY)
        
        if isPresenting {
            guard let toVC = transitionContext.viewController(forKey: .to),
                  let toView = transitionContext.view(forKey: .to) else { return }
            
            let finalFrame = transitionContext.finalFrame(for: toVC)
            let finalCenter = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
            
            // Prepare view
            toView.frame = finalFrame
            toView.layer.masksToBounds = true
            toView.layer.cornerRadius = 12
            container.addSubview(toView)
            
            // Start from button center + scale
            let sx = max(0.02, originInContainer.width / max(1, finalFrame.width))
            let sy = max(0.02, originInContainer.height / max(1, finalFrame.height))
            toView.transform = CGAffineTransform(scaleX: sx, y: sy)
            toView.center = originCenter
            
            // Animate to identity
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.35,
                           options: [.curveEaseInOut],
                           animations: {
                toView.transform = .identity
                toView.center = finalCenter
                toView.layer.cornerRadius = 0
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            let startCenter = fromView.center
            
            let fullFrame = transitionContext.containerView.bounds
            let sx = max(0.02, originInContainer.width / max(1, fullFrame.width))
            let sy = max(0.02, originInContainer.height / max(1, fullFrame.height))
            
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 0.95,
                           initialSpringVelocity: 0.0,
                           options: [.curveEaseInOut],
                           animations: {
                fromView.transform = CGAffineTransform(scaleX: sx, y: sy)
                fromView.center = originCenter
                fromView.layer.cornerRadius = 12
            }, completion: { finished in
                // Reset any transforms to avoid affecting reusable views
                fromView.transform = .identity
                fromView.center = startCenter
                transitionContext.completeTransition(finished)
            })
        }
    }
}

// MARK: - Transitioning Delegate

final class FavoritesTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = FavoritesTransitioningDelegate()
    var originFrame: CGRect = .zero
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FavoritesPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FavoritesGrowAnimator(isPresenting: true, originFrame: originFrame)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FavoritesGrowAnimator(isPresenting: false, originFrame: originFrame)
    }
}
