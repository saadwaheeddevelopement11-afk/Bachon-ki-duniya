//
//  HomeViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit
import SDWebImage

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private var homeItems: [HomeItem] = []
    private var isLoading = false
    
    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 16
    private let sectionInset: CGFloat = 16
    private let loadingAnimationKey = "kids.loading.wiggle"
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationBar()
        setupLanguageObserver()
        fetchCategories()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register default grid cell
        collectionView.register(
            UINib(nibName: "HomeListingColvCell", bundle: nil),
            forCellWithReuseIdentifier: "HomeListingColvCell"
        )
        
        // Register first banner cell (only index 0)
        collectionView.register(
            UINib(nibName: "HomeFirstCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "HomeFirstCollectionViewCell"
        )
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = spacing
            layout.minimumLineSpacing = spacing
            layout.sectionInset = UIEdgeInsets(top: 0, left: sectionInset, bottom: 0, right: sectionInset)
        }
        
        // Set semantic content based on current language
        updateSemanticContent()
    }
    
    private func setupNavigationBar() {
        let languageButton = UIBarButtonItem(
            title: LanguageManager.shared.isRTL() ? "🌐 لغات" : "🌐 Languages",
            style: .plain,
            target: self,
            action: #selector(languageButtonTapped)
        )
        navigationItem.rightBarButtonItem = languageButton
        
        // Update title based on language
        navigationItem.title = LanguageManager.shared.isRTL() ? "الصفحة الرئيسية" : "Home"
    }
    
    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: NSNotification.Name("LanguageChanged"),
            object: nil
        )
    }
    
    @objc private func languageChanged() {
        // Reload categories with new language
        fetchCategories()
        updateSemanticContent()
        setupNavigationBar()
    }
    
    private func updateSemanticContent() {
        if LanguageManager.shared.isRTL() {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
            collectionView.semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
            collectionView.semanticContentAttribute = .forceLeftToRight
        }
    }
    
    @objc private func languageButtonTapped() {
        if let languageVC = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") {
            performPlayfulPush(languageVC)
        }
    }
    
    // MARK: - API Calls
    private func fetchCategories() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        isLoading = true
        startPlayfulLoadingAnimation()
        collectionView.alpha = 0.7
        
        APIManager.shared.fetchCategories(languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.stopPlayfulLoadingAnimation()
                
                print(result)
                
                switch result {
                case .success(let categories):
                    self?.processCategories(categories)
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func processCategories(_ categories: [Category]) {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        var processedItems: [HomeItem] = []
        
        for category in categories {
            if let translation = category.getTranslation(for: currentLanguage) {
                let homeItem = HomeItem(
                    id: category.id,
                    imageUrl: category.img ?? "",
                    title: translation.name,
                    description: translation.description,
                    color: category.color,
                    order: category.order,
                    hasSubcategories: category.hasSubcategories  // Pass this information
                )
                processedItems.append(homeItem)
            } else if let defaultTranslation = category.getTranslation(for: "en") {
                // Fallback to English if current language translation not available
                let homeItem = HomeItem(
                    id: category.id,
                    imageUrl: category.img ?? "",
                    title: defaultTranslation.name,
                    description: defaultTranslation.description,
                    color: category.color,
                    order: category.order,
                    hasSubcategories: category.hasSubcategories  // Pass this information
                )
                processedItems.append(homeItem)
            }
        }
        
        // Sort by order
        processedItems.sort(by: { $0.order < $1.order })
        
        self.homeItems = processedItems
        collectionView.reloadData()
        animateContentEntrance()
    }
    
    private func showError(_ error: Error) {
        let alertMessage = LanguageManager.shared.isRTL() ?
            "فشل تحميل الفئات: \(error.localizedDescription)" :
            "Failed to load categories: \(error.localizedDescription)"
        
        let retryTitle = LanguageManager.shared.isRTL() ? "إعادة المحاولة" : "Retry"
        let okTitle = LanguageManager.shared.isRTL() ? "موافق" : "OK"
        
        let alert = UIAlertController(
            title: LanguageManager.shared.isRTL() ? "خطأ" : "Error",
            message: alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: retryTitle, style: .default) { [weak self] _ in
            self?.fetchCategories()
        })
        alert.addAction(UIAlertAction(title: okTitle, style: .cancel))
        present(alert, animated: true)
    }
    
    // Helper method to load image from URL with caching
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        let placeholder = UIImage(named: "placeholder")
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            imageView.image = placeholder
            return
        }
        
        imageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
    }
    
    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            self.present(vc, animated: true)
        }
    }
    
    private func startPlayfulLoadingAnimation() {
        guard let loadingIndicator else { return }
        loadingIndicator.startAnimating()
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            loadingIndicator.transform = CGAffineTransform(scaleX: 1.18, y: 1.18)
            loadingIndicator.alpha = 0.8
        }
        
        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation")
        wiggle.values = [-0.06, 0.06, -0.04, 0.04, 0]
        wiggle.duration = 0.8
        wiggle.repeatCount = .infinity
        wiggle.isAdditive = true
        loadingIndicator.layer.add(wiggle, forKey: loadingAnimationKey)
    }
    
    private func stopPlayfulLoadingAnimation() {
        guard let loadingIndicator else { return }
        loadingIndicator.layer.removeAnimation(forKey: loadingAnimationKey)
        loadingIndicator.layer.removeAllAnimations()
        loadingIndicator.stopAnimating()
        loadingIndicator.transform = .identity
        loadingIndicator.alpha = 1
    }
    
    private func animateContentEntrance() {
        collectionView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) { [weak self] in
            self?.collectionView.alpha = 1
            self?.collectionView.transform = .identity
        }
    }
    
    private func performPlayfulPush(_ viewController: UIViewController) {
        guard let navigationController else { return }
        let transition = CATransition()
        transition.duration = 0.38
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        navigationController.view.layer.add(transition, forKey: kCATransition)
        navigationController.pushViewController(viewController, animated: false)
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homeItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = homeItems[indexPath.item]
        let isRTL = LanguageManager.shared.isRTL()
        
        if indexPath.item == 0 {
            guard let firstCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "HomeFirstCollectionViewCell",
                for: indexPath
            ) as? HomeFirstCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            loadImage(from: item.imageUrl, into: firstCell.bannerImageView)
            firstCell.titleLbl.text = item.title
            firstCell.descriptionLbl.text = item.description
            firstCell.titleLbl.textAlignment = .center //isRTL ? .right : .left
            firstCell.descriptionLbl.textAlignment = isRTL ? .right : .left
            
            return firstCell
        }
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "HomeListingColvCell",
            for: indexPath
        ) as? HomeListingColvCell else {
            return UICollectionViewCell()
        }
        
        loadImage(from: item.imageUrl, into: cell.bannerImageView)
        cell.titleLbl.text = item.title
        cell.descriptionLbl.text = item.description
        
        // Apply background color if available
//        if !item.color.isEmpty {
//            cell.contentView.backgroundColor = UIColor(hex: item.color)
//        }
        
        // Handle RTL text alignment
        if isRTL {
            cell.titleLbl.textAlignment = .right
            cell.descriptionLbl.textAlignment = .right
        } else {
            cell.titleLbl.textAlignment = .left
            cell.descriptionLbl.textAlignment = .left
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = homeItems[indexPath.item]
        navigateToAppropriateViewController(item: item)
    }

    private func navigateToAppropriateViewController(item: HomeItem) {
        // Determine which view controller to push based on category title or ID
        
        switch item.title {
        case CategoryType.kidsStories.rawValue:
            navigateToKidsStories(with: item)
            
        case CategoryType.islamicKnowledge.rawValue:
            navigateToIslamicKnowledge(with: item)
            
        case CategoryType.generalKnowledge.rawValue:
            navigateToGeneralKnowledge(with: item)
            
        case CategoryType.kidsShows.rawValue:
            navigateToKidsShows(with: item)
            
        case CategoryType.bedtimeStories.rawValue:
            navigateToBedtimeStories(with: item)
            
        case CategoryType.growWell.rawValue:
            navigateToGeneralKnowledge(with: item)
//            navigateToGrowWell(with: item)
            
        case CategoryType.poems.rawValue:
            navigateToPoems(with: item)
            
        case CategoryType.letsLearn.rawValue:
            navigateToLetsLearn(with: item)
            
        case CategoryType.riddles.rawValue:
            navigateToRiddles(with: item)
            
        default:
            // Fallback to generic IslamicKnowledgeViewController
            navigateToGenericCategory(with: item)
        }
    }

    // MARK: - Navigation Methods
    private func navigateToKidsStories(with item: HomeItem) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateToIslamicKnowledge(with item: HomeItem) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateToGeneralKnowledge(with item: HomeItem) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateToKidsShows(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsShowsViewController") as? KidsShowsViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToBedtimeStories(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "BedtimeStoriesViewController") as? BedtimeStoriesViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToGrowWell(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "GrowWellViewController") as? GrowWellViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToPoems(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "PoemsViewController") as? PoemsViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToLetsLearn(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "LetsLearnViewController") as? LetsLearnViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToRiddles(with item: HomeItem) {
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "RiddlesViewController") as? RiddlesViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }

    private func navigateToGenericCategory(with item: HomeItem) {
        // Fallback to generic view controller
//        if let vc = storyboard?.instantiateViewController(withIdentifier: "IslamicKnowledgeViewController") as? IslamicKnowledgeViewController {
//            vc.categoryId = item.id
//            vc.categoryTitle = item.title
//            vc.hasSubcategories = item.hasSubcategories
//            navigationController?.pushViewController(vc, animated: true)
//        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let availableWidth = totalWidth - (sectionInset * 2)
        
        if indexPath.item == 0 {
            // First item (banner) takes full width
            let bannerHeight: CGFloat = 210
            return CGSize(width: availableWidth, height: bannerHeight)
        } else {
            // All other items: 2 per row
            let itemWidth = (availableWidth - spacing) / itemsPerRow
            let itemHeight = itemWidth * 1.1 // Aspect ratio for category cells
            return CGSize(width: itemWidth, height: itemHeight)
        }
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

