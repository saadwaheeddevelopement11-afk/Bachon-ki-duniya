//
//  HomeViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    private var homeItems: [HomeItem] = []
    private var isLoading = false
    
    private let itemsPerRow: CGFloat = 2
    private let spacing: CGFloat = 16
    private let sectionInset: CGFloat = 6
    
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
        
        // Register both cell types
        collectionView.register(
            UINib(nibName: "HomeListingColvCell", bundle: nil),
            forCellWithReuseIdentifier: "HomeListingColvCell"
        )
        
        collectionView.register(
            UINib(nibName: "HomeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: HomeCollectionViewCell.reuseIdentifier
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
            navigationController?.pushViewController(languageVC, animated: true)
        }
    }
    
    // MARK: - API Calls
    private func fetchCategories() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        isLoading = true
        loadingIndicator?.startAnimating()
        
        APIManager.shared.fetchCategories(languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingIndicator?.stopAnimating()
                
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
                    imageUrl: category.img,
                    title: translation.name,
                    description: translation.description,
                    color: category.color,
                    order: category.order
                )
                processedItems.append(homeItem)
            } else if let defaultTranslation = category.getTranslation(for: "en") {
                // Fallback to English if current language translation not available
                let homeItem = HomeItem(
                    id: category.id,
                    imageUrl: category.img,
                    title: defaultTranslation.name,
                    description: defaultTranslation.description,
                    color: category.color,
                    order: category.order
                )
                processedItems.append(homeItem)
            }
        }
        
        // Sort by order
        processedItems.sort(by: { $0.order < $1.order })
        
        // Add banner item at the end
        let bannerItem = HomeItem(
            id: -1, // Special ID for banner
            imageUrl: "",
            title: "",
            description: "",
            color: "",
            order: processedItems.count
        )
        processedItems.append(bannerItem)
        
        self.homeItems = processedItems
        collectionView.reloadData()
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
        guard let url = URL(string: urlString) else { return }
        
        // Simple caching mechanism
        let cacheKey = urlString as NSString
        if let cachedImage = ImageCache.shared.getImage(forKey: cacheKey) {
            imageView.image = cachedImage
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else { return }
            
            // Cache the image
            ImageCache.shared.setImage(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
    
    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            self.present(vc, animated: true)
        }
    }
}

// MARK: - Image Cache Helper
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {}
    
    func getImage(forKey key: NSString) -> UIImage? {
        return cache.object(forKey: key)
    }
    
    func setImage(_ image: UIImage, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homeItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = homeItems[indexPath.item]
        let isLastItem = indexPath.item == homeItems.count - 1
        
        if isLastItem {
            // Banner cell
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HomeCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? HomeCollectionViewCell else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: "Banner")
            return cell
        } else {
            // Regular category cell
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "HomeListingColvCell",
                for: indexPath
            ) as? HomeListingColvCell else {
                return UICollectionViewCell()
            }
            
            loadImage(from: item.imageUrl, into: cell.bannerImageView)
            cell.titleLbl.text = item.title
            cell.descriptionLbl.text = item.description
            
            // Handle RTL text alignment
            if LanguageManager.shared.isRTL() {
                cell.titleLbl.textAlignment = .right
                cell.descriptionLbl.textAlignment = .right
            } else {
                cell.titleLbl.textAlignment = .left
                cell.descriptionLbl.textAlignment = .left
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = homeItems[indexPath.item]
        let isLastItem = indexPath.item == homeItems.count - 1
        
        if isLastItem {
            print("Banner tapped")
        } else {
            navigateToCategory(with: item.id, title: item.title)
        }
    }
    
    private func navigateToCategory(with id: Int, title: String) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "IslamicKnowledgeViewController") as? IslamicKnowledgeViewController {
            vc.categoryId = id
            vc.categoryTitle = title
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let isLastItem = indexPath.item == homeItems.count - 1
        
        if isLastItem {
            let contentWidth = totalWidth - (sectionInset * 2)
            let bannerHeight: CGFloat = 200
            return CGSize(width: contentWidth, height: bannerHeight)
        }
        
        let availableWidth = (totalWidth - (sectionInset * 2)) - (spacing * (itemsPerRow - 1))
        let itemWidth = availableWidth / itemsPerRow
        let itemHeight = itemWidth * 1.35
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
