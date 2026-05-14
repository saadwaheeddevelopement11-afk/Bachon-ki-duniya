import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    private let selectionIndicator = UIView()
    private let blurBackgroundView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
        v.isUserInteractionEnabled = false
        return v
    }()
    
    private enum Style {
        static let horizontalInset: CGFloat = 24
        static let floatingBottomPadding: CGFloat = 12
        static let barHeight: CGFloat = 74
        static let indicatorWidth: CGFloat = 32
        static let indicatorHeight: CGFloat = 4
        static let indicatorBottomInset: CGFloat = 10
        static let borderWidth: CGFloat = 1
        /// Slightly darker than before so the pill edge reads clearly on blur.
        static let tabBarBorder = UIColor(white: 0.72, alpha: 1)
        /// Extra space above the tab bar so the last list row isn’t tight to the pill.
        static let scrollBottomExtraPadding: CGFloat = 8
        static let selectionPurple = UIColor(red: 0.62, green: 0.52, blue: 0.98, alpha: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureTabBarItems()
        configureAppearance()
        configureSelectionIndicator()
        applyLocalizedTabAccessibility()
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange), name: .languageDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appLanguageDidChange() {
        applyLocalizedTabAccessibility()
        layoutSelectionIndicator(animated: true)
    }

    private func applyLocalizedTabAccessibility() {
        let keys: [AppStringKey] = [.tabHome, .tabSearch, .tabLibrary, .tabProfile]
        for (index, vc) in (viewControllers ?? []).enumerated() where index < keys.count {
            vc.tabBarItem.accessibilityLabel = AppL10n.t(keys[index])
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutFloatingTabBarIfNeeded()
        layoutBlurBackground()
        clearSystemTabBarBackgroundFill()
        updateChildBottomSafeInsetsForFloatingTabBar()
        layoutSelectionIndicator(animated: false)
        tabBar.bringSubviewToFront(selectionIndicator)
    }
    
    private func configureTabBarItems() {
        viewControllers?.forEach { vc in
            guard let item = vc.tabBarItem else { return }
            item.title = nil
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal)
            item.imageInsets = .zero
            item.titlePositionAdjustment = .zero
        }
    }
    
    private func configureAppearance() {
        tabBar.isTranslucent = true
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        let hiddenTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 0.01),
            .foregroundColor: UIColor.clear
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = hiddenTitle
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = hiddenTitle
        appearance.stackedLayoutAppearance.normal.iconColor = nil
        appearance.stackedLayoutAppearance.selected.iconColor = nil
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.tintColor = Style.selectionPurple
        tabBar.unselectedItemTintColor = .systemGray
    }
    
    private func configureSelectionIndicator() {
        selectionIndicator.backgroundColor = Style.selectionPurple
        selectionIndicator.layer.cornerRadius = Style.indicatorHeight / 2
        selectionIndicator.isUserInteractionEnabled = false
        tabBar.addSubview(selectionIndicator)
    }
    
    private func layoutBlurBackground() {
        if blurBackgroundView.superview != tabBar {
            tabBar.insertSubview(blurBackgroundView, at: 0)
        }
        blurBackgroundView.frame = tabBar.bounds
        let pillRadius = Style.barHeight / 2
        blurBackgroundView.layer.cornerRadius = pillRadius
        blurBackgroundView.clipsToBounds = true
    }
    
    /// Removes the opaque system fill (`_UIBarBackground` / inner `UIImageView`) so the blur shows through.
    private func clearSystemTabBarBackgroundFill() {
        for subview in tabBar.subviews {
            let typeName = String(describing: type(of: subview))
            guard typeName.contains("BarBackground") else { continue }
            subview.backgroundColor = .clear
            subview.isOpaque = false
            for inner in subview.subviews {
                inner.backgroundColor = .clear
                inner.isOpaque = false
                if let iv = inner as? UIImageView {
                    iv.image = nil
                    iv.highlightedImage = nil
                }
            }
        }
    }
    
    private func layoutFloatingTabBarIfNeeded() {
        let bottomMargin = Style.floatingBottomPadding + view.safeAreaInsets.bottom
        
        var frame = tabBar.frame
        frame.size.height = Style.barHeight
        frame.origin.x = Style.horizontalInset
        frame.size.width = view.bounds.width - (Style.horizontalInset * 2)
        frame.origin.y = view.bounds.height - Style.barHeight - bottomMargin
        tabBar.frame = frame
        
        let pillRadius = Style.barHeight / 2
        if abs(tabBar.layer.cornerRadius - pillRadius) > 0.5 {
            tabBar.layer.cornerRadius = pillRadius
        }
        tabBar.layer.masksToBounds = false
        tabBar.layer.borderWidth = Style.borderWidth
        tabBar.layer.borderColor = Style.tabBarBorder.cgColor
        
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.08
        tabBar.layer.shadowRadius = 16
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 8)
    }
    
    /// Pushes scroll content above the floating tab bar (`UITableView` / `UIScrollView` use safe area when pinned to superview bottom).
    private func updateChildBottomSafeInsetsForFloatingTabBar() {
        guard let vcs = viewControllers, tabBar.frame.minY < view.bounds.height else { return }
        let overlap = view.bounds.height - tabBar.frame.minY + Style.scrollBottomExtraPadding
        for vc in vcs {
            var ins = vc.additionalSafeAreaInsets
            ins.bottom = overlap
            vc.additionalSafeAreaInsets = ins
        }
    }
    
    private func layoutSelectionIndicator(animated: Bool) {
        guard tabBar.bounds.width > 0, let count = viewControllers?.count, count > 0 else { return }
        
        let segment = tabBar.bounds.width / CGFloat(count)
        let idx = CGFloat(selectedIndex)
        // `selectedIndex` follows `viewControllers` order; tab bar mirrors items in RTL, so map to visual slot from leading edge.
        let visualSlot: CGFloat
        if tabBar.effectiveUserInterfaceLayoutDirection == .rightToLeft {
            visualSlot = CGFloat(count - 1) - idx
        } else {
            visualSlot = idx
        }
        let centerX = segment * visualSlot + segment / 2
        let width = Style.indicatorWidth
        let height = Style.indicatorHeight
        let frame = CGRect(
            x: centerX - width / 2,
            y: tabBar.bounds.height - Style.indicatorBottomInset - height,
            width: width,
            height: height
        )
        
        let updates = { self.selectionIndicator.frame = frame }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.6, options: [.curveEaseOut]) {
                updates()
            }
        } else {
            updates()
        }
    }
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        layoutSelectionIndicator(animated: true)
    }
}
