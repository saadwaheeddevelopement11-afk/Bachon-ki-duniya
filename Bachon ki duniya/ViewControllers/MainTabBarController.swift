import UIKit

final class MainTabBarController: UITabBarController {
    
    private var didLayoutOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureAppearance()
        configureItemSpacing()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutFloatingTabBarIfNeeded()
    }
    
    private func configureAppearance() {
        tabBar.isTranslucent = true
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .white
        
        let normalColor = UIColor.systemGray
        let selectedColor = UIColor.systemPink
        
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .regular)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        
        tabBar.tintColor = selectedColor
        tabBar.unselectedItemTintColor = normalColor
    }
    
    private func configureItemSpacing() {
        // Adds space between icon and title (move icon up, title down).
        tabBar.items?.forEach { item in
            item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 6)
            item.imageInsets = UIEdgeInsets(top: -2, left: 0, bottom: 2, right: 0)
        }
    }
    
    private func layoutFloatingTabBarIfNeeded() {
        // Avoid fighting Auto Layout repeatedly.
        if didLayoutOnce { return }
        didLayoutOnce = true
        
        let horizontalInset: CGFloat = 22
        let bottomInset: CGFloat = 22
        let height: CGFloat = 88
        
        var frame = tabBar.frame
        frame.size.height = height
        frame.origin.x = horizontalInset
        frame.size.width = view.bounds.width - (horizontalInset * 2)
        frame.origin.y = view.bounds.height - height - bottomInset
        tabBar.frame = frame
        
        tabBar.layer.cornerRadius = 28
        tabBar.layer.masksToBounds = false
        
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.12
        tabBar.layer.shadowRadius = 12
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 6)
    }
}

