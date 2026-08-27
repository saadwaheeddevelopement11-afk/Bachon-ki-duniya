//
//  StoriesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 07/04/2026.
//

import UIKit
import SDWebImage

class StoriesViewController: UIViewController {
    
    var seriesId = 0
    var seriesTitle = ""
    /// Poster / banner for this show (from series list or category thumb).
    var topBannerImage = ""
    
    @IBOutlet weak var seriesTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topBanner: UIImageView!
    private var episodes: [StoryEpisode] = []
    private var languageObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        if seriesTitle.isEmpty {
            seriesTitle = AppL10n.t(.storiesDefaultTitle)
        }
        applyTitle()
        setupBanner()
        setupTableView()
        fetchEpisodes()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.fetchEpisodes()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(bookmarksDidChange),
            name: .bookmarksDidChange,
            object: nil
        )
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func bookmarksDidChange() {
        tableView.reloadData()
    }

    private func applyTitle() {
        title = seriesTitle
        seriesTitleLabel?.text = seriesTitle
    }

    private func setupBanner() {
        let placeholder = UIImage(named: "placeholder")
        guard !topBannerImage.isEmpty, let url = URL(string: topBannerImage) else {
            topBanner?.image = placeholder
            return
        }
        topBanner?.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .automatic
        
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
    }
    
    private func fetchEpisodes() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchEpisodes(seriesId: seriesId, languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let episodes):
                    self?.episodes = episodes
                    // Keep the show name passed from navigation — season titles are "Season 1", etc.
                    self?.applyTitle()
                    self?.applyBannerFallbackIfNeeded()
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching episodes for series: \(error)")
                }
            }
        }
    }

    private func applyBannerFallbackIfNeeded() {
        guard topBannerImage.isEmpty,
              let thumb = episodes.first?.thumbnailURL,
              !thumb.isEmpty,
              let url = URL(string: thumb) else { return }
        topBannerImage = thumb
        topBanner?.sd_setImage(
            with: url,
            placeholderImage: UIImage(named: "placeholder"),
            options: [.retryFailed, .continueInBackground, .highPriority]
        )
    }
    
    private func configureEpisodeCell(_ cell: KidsStoriesTableViewCell, episode: StoryEpisode) {
        cell.titleLbl.text = episode.title
        cell.textLbl.text = episode.description
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.configureBookmark(isBookmarked: BookmarkStore.isBookmarked(episode.id))
        cell.onBookmarkTapped = { [weak self] in
            self?.toggleBookmark(for: episode)
        }

        let placeholder = UIImage(named: "placeholder")
        guard let imageUrl = episode.thumbnailURL, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.mainImageView.image = placeholder
            return
        }

        cell.mainImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
    }

    private func toggleBookmark(for episode: StoryEpisode) {
        BookmarkStore.toggle(
            episodeId: episode.id,
            title: episode.title,
            description: episode.description,
            thumbnailURL: episode.thumbnailURL,
            videoURL: episode.videoURL
        ) { [weak self] result in
            if case .failure(let error) = result {
                let alert = UIAlertController(
                    title: AppL10n.t(.errorTitle),
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
                self?.present(alert, animated: true)
            }
            self?.tableView.reloadData()
        }
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension StoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KidsStoriesTableViewCell.reuseIdentifier, for: indexPath) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        
        let episode = episodes[indexPath.row]
        configureEpisodeCell(cell, episode: episode)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let episode = episodes[indexPath.row]

        if episode.isHTMLGame, let htmlURL = episode.htmlURL {
            let gameVC = HTMLGameViewController()
            gameVC.gameTitleText = episode.title
            gameVC.htmlURLString = htmlURL
            gameVC.modalPresentationStyle = .fullScreen
            present(gameVC, animated: true)
            return
        }

        guard let context = VideoPlaybackContext.from(episode: episode) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
