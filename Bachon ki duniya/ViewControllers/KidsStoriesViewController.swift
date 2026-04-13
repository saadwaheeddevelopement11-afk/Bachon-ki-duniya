//
//  KidsStoriesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class KidsStoriesViewController: UIViewController {
    
    var categoryId = 0
    var categoryTitle = ""
    var hasSubcategories = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?
    
    // Data arrays
    private var subcategories: [Subcategory] = []
    private var recentEpisodes: [Episode] = [] // Replace with your actual episode model
    private var isLoading = false
    private let loadingAnimationKey = "kids.loading.wiggle"
    
    // Section enum
    private enum Section: Int, CaseIterable {
        case subcategories
        case recentEpisodes
        
        var title: String {
            switch self {
            case .recentEpisodes:
                return LanguageManager.shared.isRTL() ? "الحلقات الأخيرة" : "Recent Episodes"
            case .subcategories:
                return ""
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigation()
        fetchData()
    }
    
    private func setupNavigation() {
        title = categoryTitle
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add back button if needed
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register SubCategoriesCell
        let subcategoryNib = UINib(nibName: "SubCategoriesCell", bundle: nil)
        tableView.register(subcategoryNib, forCellReuseIdentifier: "SubCategoriesCell")
        
        // Register KidsStoriesTableViewCell for episodes
        let episodeNib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableView.register(episodeNib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
        
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
        // Set estimated heights for dynamic cells
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func fetchData() {
        isLoading = true
        startPlayfulLoadingAnimation()
        tableView.alpha = 0.7
        // Always fetch subcategories first using categoryId from Home.
        fetchSubcategories()
    }
    
    private func fetchSubcategories() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        
        // API Call: GET /subcategories/{categoryId}?lang={languageCode}
        APIManager.shared.fetchSubcategories(categoryId: categoryId, languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let subcategories):
                    self?.subcategories = subcategories.sorted(by: { $0.order < $1.order })
                    print("Fetched \(subcategories.count) subcategories")
                    self?.tableView.reloadData()
                    // After fetching subcategories, fetch episodes
                    self?.fetchRecentEpisodes()
                    
                case .failure(let error):
                    print("Error fetching subcategories: \(error)")
                    // If subcategories fail, still try loading recent episodes.
                    self?.fetchRecentEpisodes()
                }
            }
        }
    }
    
    private func fetchRecentEpisodes() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        
        // Fetch recent episodes for this category
        APIManager.shared.fetchEpisodes(categoryId: categoryId, languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.stopPlayfulLoadingAnimation()
                
                switch result {
                case .success(let episodes):
                    self?.recentEpisodes = episodes
                    self?.tableView.reloadData()
                    self?.animateContentEntrance()
                    
                case .failure(let error):
                    print("Error fetching episodes: \(error)")
                    // Still reload table to show subcategories if available
                    self?.tableView.reloadData()
                    self?.animateContentEntrance()
                    if self?.subcategories.isEmpty == true {
                        self?.showError(error)
                    }
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alertMessage = LanguageManager.shared.isRTL() ?
            "فشل تحميل المحتوى: \(error.localizedDescription)" :
            "Failed to load content: \(error.localizedDescription)"
        
        let alert = UIAlertController(
            title: LanguageManager.shared.isRTL() ? "خطأ" : "Error",
            message: alertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
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
        tableView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        UIView.animate(
            withDuration: 0.42,
            delay: 0,
            usingSpringWithDamping: 0.78,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut]
        ) { [weak self] in
            self?.tableView.alpha = 1
            self?.tableView.transform = .identity
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

// MARK: - UITableViewDataSource
extension KidsStoriesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections = 0
        
        // Show subcategories section when we have subcategories.
        if !subcategories.isEmpty {
            sections += 1
        }
        
        // Show recent episodes section only if we have episodes
        if !recentEpisodes.isEmpty {
            sections += 1
        }
        
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = getSectionType(for: section)
        
        switch sectionType {
        case .subcategories:
            return subcategories.count
        case .recentEpisodes:
            return recentEpisodes.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = getSectionType(for: indexPath.section)
        
        switch sectionType {
        case .subcategories:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "SubCategoriesCell",
                for: indexPath
            ) as? SubCategoriesCell else {
                return UITableViewCell()
            }
            
            let subcategory = subcategories[indexPath.row]
            let currentLanguage = LanguageManager.shared.currentLanguageCode
            
            // Get translation for current language
            if let translation = subcategory.getTranslation(for: currentLanguage) {
                configureSubcategoryCell(
                    cell,
                    withTitle: translation.name,
                    description: translation.description,
                    imageUrl: subcategory.img
                )
            } else if let defaultTranslation = subcategory.getTranslation(for: "en") {
                // Fallback to English
                configureSubcategoryCell(
                    cell,
                    withTitle: defaultTranslation.name,
                    description: defaultTranslation.description,
                    imageUrl: subcategory.img
                )
            }
            
            return cell
            
        case .recentEpisodes:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? KidsStoriesTableViewCell else {
                return UITableViewCell()
            }
            
            let episode = recentEpisodes[indexPath.row]
            // Configure your episode cell here
            // cell.configure(with: episode)
            
            return cell
        }
    }
    
    private func getSectionType(for section: Int) -> Section {
        // If we have subcategories section, it will be at index 0
        if !subcategories.isEmpty {
            if section == 0 {
                return .subcategories
            } else {
                return .recentEpisodes
            }
        } else {
            // If no subcategories, everything is recent episodes
            return .recentEpisodes
        }
    }
}

// MARK: - UITableViewDelegate
extension KidsStoriesViewController: UITableViewDelegate {
    private var subcategoryCellSpacing: CGFloat { 12 }
    private var subcategoryItemHeight: CGFloat { 190 }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionType = getSectionType(for: indexPath.section)
        
        switch sectionType {
        case .subcategories:
            let subcategory = subcategories[indexPath.row]
            let currentLanguage = LanguageManager.shared.currentLanguageCode
            let translation = subcategory.getTranslation(for: currentLanguage) ??
                             subcategory.getTranslation(for: "en")
            
            // Navigate to episodes of this subcategory
            navigateToEpisodes(for: subcategory, title: translation?.name ?? "Episodes")
            
        case .recentEpisodes:
            let episode = recentEpisodes[indexPath.row]
            // Navigate to episode detail
            navigateToEpisodeDetail(episode)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = getSectionType(for: section)
        if sectionType == .subcategories {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = sectionType.title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = getSectionType(for: section)
        return sectionType == .subcategories ? CGFloat.leastNormalMagnitude : 50
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {        
        
        let sectionType = getSectionType(for: indexPath.section)
        switch sectionType {
        case .subcategories:
            return subcategoryItemHeight + subcategoryCellSpacing
        case .recentEpisodes:
            return 120 // Fixed height for episodes
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sectionType = getSectionType(for: indexPath.section)
        guard sectionType == .subcategories else {
            cell.contentView.frame = cell.bounds
            return
        }

        let verticalInset = subcategoryCellSpacing / 2
        cell.contentView.frame = cell.bounds.inset(by: UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0))
    }
    
    // MARK: - Navigation Methods
    private func navigateToEpisodes(for subcategory: Subcategory, title: String) {
        if let seriesVC = storyboard?.instantiateViewController(withIdentifier: "SeriesViewController") as? SeriesViewController {
            // Pass tapped subcategory id as category_id for /series API
            seriesVC.categoryId = subcategory.id
            seriesVC.categoryTitle = title
            performPlayfulPush(seriesVC)
        }
    }
    
    private func navigateToEpisodeDetail(_ episode: Episode) {
        // Navigate to episode detail view controller
//        if let detailVC = storyboard?.instantiateViewController(withIdentifier: "EpisodeDetailViewController") as? EpisodeDetailViewController {
//            detailVC.episode = episode
//            navigationController?.pushViewController(detailVC, animated: true)
//        }
    }
    
    private func configureSubcategoryCell(
        _ cell: SubCategoriesCell,
        withTitle title: String,
        description: String,
        imageUrl: String?
    ) {
        cell.titleLbl.text = title
        cell.descriptionLbl.text = description
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.descriptionLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        
        guard let imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.bgImage.image = UIImage(named: "placeholder")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                cell.bgImage.image = image
            }
        }.resume()
    }
}
