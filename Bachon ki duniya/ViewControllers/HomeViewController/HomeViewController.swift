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
    private var tableSections: [HomeCategoryTableSection] = []
    private var isLoading = false
    private let listingBackgroundPool: [String] = (1...9).map { "bg\($0)" }

    private let loadingAnimationKey = "kids.loading.wiggle"

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?
    @IBOutlet weak var contentTableView: UITableView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupNavigationBar()
        setupLanguageObserver()
        fetchCategories()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupTableView() {
        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.separatorStyle = .none
        contentTableView.backgroundColor = .clear
        contentTableView.showsVerticalScrollIndicator = false
        contentTableView.rowHeight = UITableView.automaticDimension
        contentTableView.estimatedRowHeight = 280
        if #available(iOS 15.0, *) {
            contentTableView.sectionHeaderTopPadding = 0
        }

        contentTableView.register(
            UINib(nibName: "HomeTableViewCell", bundle: nil),
            forCellReuseIdentifier: HomeTableViewCell.reuseIdentifier
        )
        contentTableView.register(
            UINib(nibName: "TopCaroselTableViewCell", bundle: nil),
            forCellReuseIdentifier: "TopCaroselTableViewCell"
        )
    }

    private func setupNavigationBar() {
        let languageButton = UIBarButtonItem(
            title: LanguageManager.shared.isRTL() ? "🌐 لغات" : "🌐 Languages",
            style: .plain,
            target: self,
            action: #selector(languageButtonTapped)
        )
        navigationItem.rightBarButtonItem = languageButton

        navigationItem.title = LanguageManager.shared.isRTL() ? "الصفحة الرئيسية" : "Home"
    }

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageDidChange,
            object: nil
        )
    }

    @objc private func languageChanged() {
        fetchCategories()
        setupNavigationBar()
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
        contentTableView.alpha = 0.7

        APIManager.shared.fetchCategories(languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.stopPlayfulLoadingAnimation()

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
        let sequencedBackgroundNames = buildRepeatingBackgroundSequence(forCount: categories.count)
        var processedItems: [HomeItem] = []

        for (index, category) in categories.enumerated() {
            if let translation = category.getTranslation(for: currentLanguage) {
                processedItems.append(HomeItem(
                    id: category.id,
                    imageUrl: category.img ?? "",
                    title: translation.name,
                    description: translation.description,
                    backgroundImageName: sequencedBackgroundNames[index],
                    color: category.color,
                    order: category.order,
                    hasSubcategories: category.hasSubcategories,
                    directSeriesId: category.directSeriesId
                ))
            } else if let defaultTranslation = category.getTranslation(for: "en") {
                processedItems.append(HomeItem(
                    id: category.id,
                    imageUrl: category.img ?? "",
                    title: defaultTranslation.name,
                    description: defaultTranslation.description,
                    backgroundImageName: sequencedBackgroundNames[index],
                    color: category.color,
                    order: category.order,
                    hasSubcategories: category.hasSubcategories,
                    directSeriesId: category.directSeriesId
                ))
            }
        }

        processedItems.sort(by: { $0.order < $1.order })
        homeItems = processedItems
        rebuildTableSections()
        contentTableView.reloadData()
        animateContentEntrance()
    }

    /// Fixed order sequence: bg1...bg9, then repeats from bg1.
    private func buildRepeatingBackgroundSequence(forCount count: Int) -> [String] {
        guard count > 0, !listingBackgroundPool.isEmpty else { return [] }
        return (0..<count).map { index in
            listingBackgroundPool[index % listingBackgroundPool.count]
        }
    }

    private func rebuildTableSections() {
        let isRTL = LanguageManager.shared.isRTL()
        let quickAccessTitle = isRTL ? "وصول سريع" : "Quick access"
        let allCategoriesTitle = isRTL ? "الفئات" : "Categories"

        var sections: [HomeCategoryTableSection] = []

        guard !homeItems.isEmpty else {
            tableSections = []
            return
        }

        // Row 0: horizontal quick access — same categories, compact tiles
        sections.append(
            HomeCategoryTableSection(
                title: "",
                items: homeItems,
                layout: .topCarousel
            )
        )
        
        // Row 1: horizontal quick access — same categories, compact tiles
        sections.append(
            HomeCategoryTableSection(
                title: quickAccessTitle,
                items: homeItems,
                layout: .horizontalQuickAccess
            )
        )

        // Row 2: full list — vertical grid, two tiles per row
        sections.append(
            HomeCategoryTableSection(
                title: allCategoriesTitle,
                items: homeItems,
                layout: .verticalGrid
            )
        )

        tableSections = sections
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

    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            present(vc, animated: true)
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
        contentTableView.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.4,
            options: [.curveEaseOut]
        ) { [weak self] in
            self?.contentTableView.alpha = 1
            self?.contentTableView.transform = .identity
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

    // MARK: - Navigation
    private func navigateToAppropriateViewController(item: HomeItem) {
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
        case CategoryType.poems.rawValue:
            navigateToPoems(with: item)
        case CategoryType.letsLearn.rawValue:
            navigateToLetsLearn(with: item)
        case CategoryType.riddles.rawValue:
            navigateToRiddles(with: item)
        default:
            navigateToGenericCategory(with: item)
        }
    }

    private func navigateToKidsStories(with item: HomeItem) {
        if !item.hasSubcategories {
            navigateDirectlyToSeries(withId: item.directSeriesId ?? item.id, title: item.title, bannerImage: item.imageUrl)
            return
        }
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateToIslamicKnowledge(with item: HomeItem) {
        if !item.hasSubcategories {
            navigateDirectlyToSeries(withId: item.directSeriesId ?? item.id, title: item.title, bannerImage: item.imageUrl)
            return
        }
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateToGeneralKnowledge(with item: HomeItem) {
        if !item.hasSubcategories {
            navigateDirectlyToSeries(withId: item.directSeriesId ?? item.id, title: item.title, bannerImage: item.imageUrl)
            return
        }
        if let vc = storyboard?.instantiateViewController(withIdentifier: "KidsStoriesViewController") as? KidsStoriesViewController {
            vc.categoryId = item.id
            vc.categoryTitle = item.title
            vc.hasSubcategories = item.hasSubcategories
            performPlayfulPush(vc)
        }
    }

    private func navigateDirectlyToSeries(withId id: Int, title: String, bannerImage: String) {
        if let seriesVC = storyboard?.instantiateViewController(withIdentifier: "SeriesViewController") as? SeriesViewController {
            seriesVC.categoryId = id
            seriesVC.categoryTitle = title
            seriesVC.topBannerImage = bannerImage
            performPlayfulPush(seriesVC)
        }
    }

    private func navigateToKidsShows(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToBedtimeStories(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToGrowWell(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToPoems(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToLetsLearn(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToRiddles(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
    
    private func navigateToGenericCategory(with item: HomeItem) {
        navigateToGeneralKnowledge(with: item)
    }
}

// MARK: - Table sections model
private struct HomeCategoryTableSection {
    let title: String
    let items: [HomeItem]
    let layout: HomeTableSectionLayout
}

private enum HomeTableSectionLayout {
    case topCarousel
    case horizontalQuickAccess
    case verticalGrid
}

// MARK: - UITableView
extension HomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableSections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = tableSections[indexPath.row]
        
        switch model.layout {
        case .topCarousel:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TopCaroselTableViewCell", for: indexPath) as? TopCaroselTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(items: model.items, isRTL: LanguageManager.shared.isRTL()) { [weak self] item in
                self?.navigateToAppropriateViewController(item: item)
            }
            return cell
            
        case .horizontalQuickAccess, .verticalGrid:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? HomeTableViewCell else {
                return UITableViewCell()
            }
            let innerWidth = tableView.bounds.width > 1 ? tableView.bounds.width : (view.bounds.width - 24)
            let rowLayout: HomeCategoryRowLayout = (model.layout == .horizontalQuickAccess) ? .horizontalQuickAccess : .verticalGrid
            cell.configure(
                title: model.title,
                items: model.items,
                layoutKind: rowLayout,
                contentWidth: innerWidth,
                isRTL: LanguageManager.shared.isRTL()
            )
            cell.onSelectItem = { [weak self] item in
                self?.navigateToAppropriateViewController(item: item)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let model = tableSections[indexPath.row]
        
        if model.layout == .topCarousel,
           let carouselCell = cell as? TopCaroselTableViewCell {
            carouselCell.configure(items: model.items, isRTL: LanguageManager.shared.isRTL()) { [weak self] item in
                self?.navigateToAppropriateViewController(item: item)
            }
            return
        }
        
        guard let homeCell = cell as? HomeTableViewCell else { return }
        let innerWidth = tableView.bounds.width > 1 ? tableView.bounds.width : (view.bounds.width - 24)
        let rowLayout: HomeCategoryRowLayout = (model.layout == .horizontalQuickAccess) ? .horizontalQuickAccess : .verticalGrid
        homeCell.configure(
            title: model.title,
            items: model.items,
            layoutKind: rowLayout,
            contentWidth: innerWidth,
            isRTL: LanguageManager.shared.isRTL()
        )
        homeCell.onSelectItem = { [weak self] item in
            self?.navigateToAppropriateViewController(item: item)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableSections[indexPath.row].layout {
        case .topCarousel:
            return 220
        case .horizontalQuickAccess, .verticalGrid:
            return UITableView.automaticDimension
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
