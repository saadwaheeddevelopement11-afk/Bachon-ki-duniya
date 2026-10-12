//
//  SwipeBackNavigationController.swift
//  Bachon ki duniya
//

import UIKit

/// Keeps edge swipe-to-pop working when the navigation bar is hidden
/// (system disables `interactivePopGestureRecognizer` without a visible back button).
final class SwipeBackNavigationController: UINavigationController {

    private var edgePopGesture: UIScreenEdgePanGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        interactivePopGestureRecognizer?.delegate = self
        interactivePopGestureRecognizer?.isEnabled = true
        installEdgePopFallback()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        // Non-animated / CATransition pushes leave the system pop gesture stuck;
        // repair after UIKit finishes updating the stack.
        DispatchQueue.main.async { [weak self] in
            self?.repairSwipeBackGesture()
        }
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        DispatchQueue.main.async { [weak self] in
            self?.repairSwipeBackGesture()
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated)
        repairSwipeBackGesture()
        return popped
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let popped = super.popToRootViewController(animated: animated)
        repairSwipeBackGesture()
        return popped
    }

    @objc private func languageDidChange() {
        updateEdgePopEdges()
    }

    private func installEdgePopFallback() {
        let edge = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePop(_:)))
        edge.delegate = self
        view.addGestureRecognizer(edge)
        edgePopGesture = edge
        updateEdgePopEdges()
    }

    private func updateEdgePopEdges() {
        let rtl = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
            || LanguageManager.shared.isRTL()
        edgePopGesture?.edges = rtl ? .right : .left
    }

    private func repairSwipeBackGesture() {
        updateEdgePopEdges()
        let canPop = viewControllers.count > 1
        guard let pop = interactivePopGestureRecognizer else {
            edgePopGesture?.isEnabled = canPop
            return
        }
        pop.delegate = self
        // Toggle to reset internal state after non-animated pushes.
        pop.isEnabled = false
        pop.isEnabled = canPop
        edgePopGesture?.isEnabled = canPop
    }

    @objc private func handleEdgePop(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard viewControllers.count > 1 else { return }

        let rtl = edgePopGesture?.edges == .right
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let distance = rtl ? -translation.x : translation.x
        let speed = rtl ? -velocity.x : velocity.x

        switch gesture.state {
        case .ended, .cancelled:
            if distance > 64 || speed > 450 {
                popViewController(animated: true)
            }
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count > 1 else { return false }
        if gestureRecognizer === interactivePopGestureRecognizer || gestureRecognizer === edgePopGesture {
            return true
        }
        return true
    }

    /// Don't let the global keyboard-dismiss tap delegate block the edge-swipe.
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === interactivePopGestureRecognizer || gestureRecognizer === edgePopGesture {
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    /// Prefer the edge-swipe over competing pan gestures on the leading edge.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer || gestureRecognizer === edgePopGesture
    }
}

extension SwipeBackNavigationController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        repairSwipeBackGesture()
    }
}

extension UINavigationController {
    /// Push with a light slide animation while keeping swipe-back reliable.
    /// Prefer this over CATransition + `animated: false`, which breaks interactive pop.
    func pushPreservingSwipeBack(_ viewController: UIViewController) {
        pushViewController(viewController, animated: true)
    }
}
