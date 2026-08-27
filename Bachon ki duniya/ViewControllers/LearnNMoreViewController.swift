//
//  LearnNMoreViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit
import SDWebImage

class LearnNMoreViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var libraryTitleLabel: UILabel!
    @IBOutlet weak var librarySubtitleLabel: UILabel!
    @IBOutlet weak var librarySearchField: UITextField!
    @IBOutlet weak var librarySearchMicPlaceholderField: UITextField!
    @IBOutlet weak var libraryMicButton: UIButton!

    private var latestCategories: [LatestEpisodeCategory] = []
    private var searchResults: [SearchEpisode] = []
    private var isShowingSearchResults = false
    private var languageObserver: NSObjectProtocol?
    private let voiceSearch = VoiceSearchHelper()
    private var searchWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearch()
        setupMicButton()
        setupVoiceSearch()
        applyLocalizedLibraryChrome()
        fetchLatestEpisodes()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.applyLocalizedLibraryChrome()
            self?.fetchLatestEpisodes()
            self?.reloadSearchIfNeeded()
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

    private func applyLocalizedLibraryChrome() {
        libraryTitleLabel.text = AppL10n.t(.libraryTitle)
        librarySubtitleLabel.text = AppL10n.t(.librarySubtitle)
        librarySearchField.placeholder = AppL10n.t(.librarySearchPlaceholder)
        librarySearchMicPlaceholderField?.isHidden = true
        librarySearchMicPlaceholderField?.isUserInteractionEnabled = false
        let rtl = LanguageManager.shared.isRTL()
        libraryTitleLabel.textAlignment = rtl ? .right : .natural
        librarySubtitleLabel.textAlignment = rtl ? .right : .natural
        librarySearchField.textAlignment = rtl ? .right : .natural
        librarySearchField.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UINib(nibName: "LibraryTblViewCell", bundle: nil), forCellReuseIdentifier: "LibraryTblViewCell")
        tableView.register(UINib(nibName: "KidsStoriesTableViewCell", bundle: nil), forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
    }

    private func setupSearch() {
        librarySearchField.isUserInteractionEnabled = true
        librarySearchField.isEnabled = true
        librarySearchField.returnKeyType = .search
        librarySearchField.clearButtonMode = .whileEditing
        librarySearchField.delegate = self
        librarySearchField.addTarget(self, action: #selector(librarySearchChanged), for: .editingChanged)
        // Ensure the field sits above decorative chrome and can become first responder.
        librarySearchField.superview?.bringSubviewToFront(librarySearchField)
    }

    private func setupMicButton() {
        libraryMicButton?.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
        updateMicAppearance(isListening: false)
    }

    private func setupVoiceSearch() {
        voiceSearch.onPartialResult = { [weak self] text in
            self?.librarySearchField.text = text
        }
        voiceSearch.onFinalResult = { [weak self] text in
            guard let self else { return }
            self.librarySearchField.text = text
            self.performLibrarySearch(query: text)
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
        libraryMicButton?.backgroundColor = isListening
            ? UIColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 0.18)
            : .clear
        libraryMicButton?.layer.cornerRadius = 25
    }

    @objc private func librarySearchChanged() {
        let query = librarySearchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchWorkItem?.cancel()

        if query.isEmpty {
            showLibraryBrowse()
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.performLibrarySearch(query: query)
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func reloadSearchIfNeeded() {
        let query = librarySearchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else {
            tableView.reloadData()
            return
        }
        performLibrarySearch(query: query)
    }

    private func showLibraryBrowse() {
        isShowingSearchResults = false
        searchResults = []
        tableView.reloadData()
    }

    private func performLibrarySearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showLibraryBrowse()
            return
        }

        APIManager.shared.searchEpisodes(query: trimmed) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                // Ignore stale responses if the field was cleared / changed.
                let current = self.librarySearchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard current == trimmed else { return }

                switch result {
                case .success(let items):
                    self.isShowingSearchResults = true
                    self.searchResults = items
                    self.tableView.reloadData()
                case .failure(let error):
                    print("Library search error: \(error)")
                    self.isShowingSearchResults = true
                    self.searchResults = []
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func fetchLatestEpisodes() {
        let languageCode = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchLatestEpisodes(languageCode: languageCode) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    self?.latestCategories = categories
                    if self?.isShowingSearchResults != true {
                        self?.tableView.reloadData()
                    }
                case .failure(let error):
                    print("Failed to fetch latest episodes: \(error)")
                }
            }
        }
    }

    private func configureSearchResultCell(_ cell: KidsStoriesTableViewCell, with item: SearchEpisode) {
        cell.titleLbl.text = item.displayTitle
        cell.textLbl.text = item.displayDescription
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.configureBookmark(isBookmarked: BookmarkStore.isBookmarked(item.id))
        cell.onBookmarkTapped = { [weak self] in
            self?.toggleBookmark(for: item)
        }

        let language = item.displayLanguageName
        cell.languageLbl?.text = language
        cell.languageLbl?.isHidden = language.isEmpty
        cell.languageLbl?.superview?.isHidden = language.isEmpty

        let placeholder = UIImage(named: "placeholder")
        guard let imageUrl = item.thumbnailURL, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.mainImageView.image = placeholder
            return
        }
        cell.mainImageView.sd_setImage(
            with: url,
            placeholderImage: placeholder,
            options: [.retryFailed, .continueInBackground, .highPriority]
        )
    }

    private func toggleBookmark(for item: SearchEpisode) {
        BookmarkStore.toggle(
            episodeId: item.id,
            title: item.displayTitle,
            description: item.displayDescription,
            thumbnailURL: item.thumbnailURL,
            videoURL: item.videoURL
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
}

extension LearnNMoreViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let query = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if query.isEmpty {
            showLibraryBrowse()
        } else {
            performLibrarySearch(query: query)
        }
        return true
    }
}

extension LearnNMoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isShowingSearchResults ? searchResults.count : latestCategories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isShowingSearchResults {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? KidsStoriesTableViewCell else {
                return UITableViewCell()
            }
            configureSearchResultCell(cell, with: searchResults[indexPath.row])
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryTblViewCell", for: indexPath) as? LibraryTblViewCell else {
            return UITableViewCell()
        }
        let category = latestCategories[indexPath.row]
        cell.configure(title: category.categoryName, episodes: category.episodes)
        cell.onSelectEpisode = { [weak self] episode in
            guard let self else { return }
            let title: String
            if let number = episode.episodeNumber {
                title = "\(category.categoryName) · E\(number)"
            } else {
                title = category.categoryName
            }
            guard let context = VideoPlaybackContext.from(episode: episode, title: title) else { return }
            VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard isShowingSearchResults else { return }
        let episode = searchResults[indexPath.row]
        guard let context = VideoPlaybackContext.from(episode: episode) else { return }
        VideoPlaybackPresenter.play(urlString: context.videoURL, context: context, from: self)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        isShowingSearchResults ? 150 : 150
    }
}
