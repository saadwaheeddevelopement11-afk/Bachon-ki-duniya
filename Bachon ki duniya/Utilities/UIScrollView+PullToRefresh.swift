//
//  UIScrollView+PullToRefresh.swift
//  Bachon ki duniya
//

import UIKit

extension UIScrollView {
    @discardableResult
    func installPullToRefresh(target: Any, action: Selector) -> UIRefreshControl {
        let control = refreshControl ?? UIRefreshControl()
        control.removeTarget(nil, action: nil, for: .valueChanged)
        control.addTarget(target, action: action, for: .valueChanged)
        refreshControl = control
        alwaysBounceVertical = true
        return control
    }

    func endPullToRefresh() {
        guard refreshControl?.isRefreshing == true else { return }
        refreshControl?.endRefreshing()
    }
}
