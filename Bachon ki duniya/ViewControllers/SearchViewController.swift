//
//  SearchViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit
import SDWebImage

class SearchViewController: UIViewController {

    @IBOutlet weak var searchContView: UIView!
    @IBOutlet weak var searchTextfield: UITextField!
    @IBOutlet weak var searchScreenTitleLabel: UILabel!
    @IBOutlet weak var searchMicPlaceholderField: UITextField!
    @IBOutlet weak var searchMicButton: UIButton!

    private let resultsTableView = UITableView(frame: .zero, style: .plain)
    private let featuredCollectionView: UICollectionView
    private var results: [SearchEpisode] = []
    private var featuredVideos: [HomeSliderVideo] = []
    private var searchWorkItem: DispatchWorkItem?
    private var languageObserver: NSObjectProtocol?
    private let voiceSearch = VoiceSearchHelper()
    private var featuredRequestID = 0

    private let searchResultRowHeight: CGFloat = 115 // was 100; +15pt
    private let featuredLimit = 6
    private let featuredColumns = 2
    private let featuredSpacing: CGFloat = 12

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        featuredCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        featuredCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        setupMicButton()
        setupVoiceSearch()
        setupResultsTable()
        setupFeaturedGrid()
        applyLocalizedSearchChrome()
        applySearchFieldDirection()
        updateContentMode(isSearching: false)
        loadFeaturedVideos()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.applyLocalizedSearchChrome()
            self?.applySearchFieldDirection()
            self?.reloadSearchResultsForCurrentLanguage()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !featuredCollectionView.isHidden {
            featuredCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    deinit {
        voiceSearch.stop()
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        view.endEditing(true)
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            present(vc, animated: true)
        }
    }

    private func applyLocalizedSearchChrome() {
        searchScreenTitleLabel.text = AppL10n.t(.searchTitle)
        searchTextfield.placeholder = AppL10n.t(.searchPlaceholder)
        searchMicPlaceholderField?.isHidden = true
        searchMicPlaceholderField?.isUserInteractionEnabled = false
        let rtl = LanguageManager.shared.isRTL()
        searchScreenTitleLabel.textAlignment = rtl ? .right : .natural
        featuredCollectionView.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    }

    private func applySearchFieldDirection() {
        let rtl = LanguageManager.shared.isRTL()
        searchTextfield.textAlignment = rtl ? .right : .natural
        searchTextfield.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    }

    private func setupMicButton() {
        searchMicButton?.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        updateMicAppearance(isListening: false)
    }

    private func setupVoiceSearch() {
        voiceSearch.onPartialResult = { [weak self] text in
            self?.searchTextfield.text = text
        }
        voiceSearch.onFinalResult = { [weak self] text in
            guard let self else { return }
            self.searchTextfield.text = text
            self.searchTextChanged()
        }
        voiceSearch.onListeningChanged = { [weak self] listening in
            self?.updateMicAppearance(isListening: listening)
        }
        voiceSearch.onError = { [weak self] error in
            guard let self else { return }
            self.updateMicAppearance(isListening: false)
            let alert = UIAlertController(
                title: AppL10n.t(.errorTitle),
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
            self.present(alert, animated: true)
        }
    }

    @objc private func micTapped() {
        view.endEditing(true)
        voiceSearch.toggle(from: self)
    }

    private func updateMicAppearance(isListening: Bool) {
        searchMicButton?.tintColor = isListening
            ? UIColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 1)
            : .clear
        searchMicButton?.backgroundColor = isListening
            ? UIColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 0.18)
            : .clear
        searchMicButton?.layer.cornerRadius = 25
    }

    private func reloadSearchResultsForCurrentLanguage() {
        let query = searchTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty {
            updateContentMode(isSearching: false)
            loadFeaturedVideos()
            return
        }
        performSearch(query: query)
    }

    private func setupSearch() {
        searchTextfield.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        searchTextfield.delegate = self
        searchTextfield.returnKeyType = .search
    }

    private func setupResultsTable() {
        resultsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultsTableView)

        NSLayoutConstraint.activate([
            resultsTableView.topAnchor.constraint(equalTo: searchContView.bottomAnchor, constant: 12),
            resultsTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            resultsTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            resultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.separatorStyle = .none
        resultsTableView.backgroundColor = .clear
        resultsTableView.contentInsetAdjustmentBehavior = .automatic
        resultsTableView.showsVerticalScrollIndicator = false
        resultsTableView.tableFooterView = UIView()
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        resultsTableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
    }

    private func setupFeaturedGrid() {
        featuredCollectionView.translatesAutoresizingMaskIntoConstraints = false
        featuredCollectionView.backgroundColor = .clear
        featuredCollectionView.alwaysBounceVertical = true
        featuredCollectionView.showsVerticalScrollIndicator = false
        featuredCollectionView.delegate = self
        featuredCollectionView.dataSource = self
        featuredCollectionView.register(
            SearchFeaturedVideoCell.self,
            forCellWithReuseIdentifier: SearchFeaturedVideoCell.reuseId
        )
        featuredCollectionView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        view.addSubview(featuredCollectionView)

        NSLayoutConstraint.activate([
            featuredCollectionView.topAnchor.constraint(equalTo: searchContView.bottomAnchor, constant: 12),
            featuredCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            featuredCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            featuredCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateContentMode(isSearching: Bool) {
        resultsTableView.isHidden = !isSearching
        featuredCollectionView.isHidden = isSearching
    }

    private func loadFeaturedVideos() {
        featuredRequestID += 1
        let requestID = featuredRequestID
        let language = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchHomeSliderVideos(languageCode: language, limit: featuredLimit) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, requestID == self.featuredRequestID else { return }
                switch result {
                case .success(let videos):
                    self.featuredVideos = Array(videos.prefix(self.featuredLimit))
                case .failure(let error):
                    print("Search featured slider error: \(error)")
                    self.featuredVideos = []
                }
                self.featuredCollectionView.reloadData()
            }
        }
    }

    @objc private func searchTextChanged() {
        let query = searchTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        searchWorkItem?.cancel()
        if query.isEmpty {
            results = []
            resultsTableView.reloadData()
            updateContentMode(isSearching: false)
            if featuredVideos.isEmpty {
                loadFeaturedVideos()
            }
            return
        }

        updateContentMode(isSearching: true)
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query)
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func performSearch(query: String) {
        APIManager.shared.searchEpisodes(query: query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                let current = self.searchTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard current == query else { return }
                self.updateContentMode(isSearching: true)
                switch result {
                case .success(let items):
                    self.results = items
                    self.resultsTableView.reloadData()
                case .failure(let error):
                    print("Search error: \(error)")
                    self.results = []
                    self.resultsTableView.reloadData()
                }
            }
        }
    }

    private func configureCell(_ cell: KidsStoriesTableViewCell, with item: SearchEpisode) {
        cell.titleLbl.text = item.displayTitle
        cell.textLbl.text = item.displayDescription
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left

        let language = item.displayLanguageName
        cell.languageLbl?.text = language
        cell.languageLbl?.isHidden = language.isEmpty
        cell.languageLbl?.superview?.isHidden = language.isEmpty

        let placeholder = UIImage(named: "placeholder")
        guard let imageUrl = item.thumbnailURL, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.mainImageView.image = placeholder
            return
        }

        cell.mainImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
    }

    private func playFeatured(_ video: HomeSliderVideo) {
        guard let context = VideoPlaybackContext.from(slider: video) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }

    private func featuredItemSize() -> CGSize {
        let width = featuredCollectionView.bounds.width
        guard width > 0 else { return CGSize(width: 160, height: 150) }
        let totalSpacing = featuredSpacing * CGFloat(featuredColumns - 1)
        let itemWidth = floor((width - totalSpacing) / CGFloat(featuredColumns))
        // Thumbnail ~ 3:2 + title line.
        let itemHeight = floor(itemWidth * 0.72) + 28
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchTextChanged()
        return true
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        configureCell(cell, with: results[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        searchResultRowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = results[indexPath.row]
        guard let context = VideoPlaybackContext.from(episode: episode) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }
}

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        featuredVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchFeaturedVideoCell.reuseId,
            for: indexPath
        ) as! SearchFeaturedVideoCell
        cell.configure(with: featuredVideos[indexPath.item], isRTL: LanguageManager.shared.isRTL())
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        featuredItemSize()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        featuredSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        featuredSpacing
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        playFeatured(featuredVideos[indexPath.item])
    }
}

// MARK: - Featured grid cell

private final class SearchFeaturedVideoCell: UICollectionViewCell {
    static let reuseId = "SearchFeaturedVideoCell"

    private let thumbImageView = UIImageView()
    private let playIcon = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentView.backgroundColor = .clear

        thumbImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbImageView.contentMode = .scaleAspectFill
        thumbImageView.clipsToBounds = true
        thumbImageView.layer.cornerRadius = 14
        thumbImageView.backgroundColor = UIColor(white: 0.92, alpha: 1)

        playIcon.translatesAutoresizingMaskIntoConstraints = false
        playIcon.image = UIImage(named: "playIcon") ?? UIImage(systemName: "play.circle.fill")
        playIcon.contentMode = .scaleAspectFit
        playIcon.tintColor = .white

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "Poppins-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        contentView.addSubview(thumbImageView)
        contentView.addSubview(playIcon)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -6),

            playIcon.centerXAnchor.constraint(equalTo: thumbImageView.centerXAnchor),
            playIcon.centerYAnchor.constraint(equalTo: thumbImageView.centerYAnchor),
            playIcon.widthAnchor.constraint(equalToConstant: 36),
            playIcon.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    func configure(with video: HomeSliderVideo, isRTL: Bool) {
        titleLabel.text = video.displayTitle
        titleLabel.textAlignment = isRTL ? .right : .left
        let placeholder = UIImage(named: "placeholder")
        if let urlString = video.thumbnailURL, !urlString.isEmpty, let url = URL(string: urlString) {
            thumbImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
        } else {
            thumbImageView.image = placeholder
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.sd_cancelCurrentImageLoad()
        thumbImageView.image = nil
        titleLabel.text = nil
    }
}
