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
    
    private let resultsTableView = UITableView(frame: .zero, style: .plain)
    private var results: [SearchEpisode] = []
    private var searchWorkItem: DispatchWorkItem?
    private var languageObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        setupResultsTable()
        applyLocalizedSearchChrome()
        applySearchFieldDirection()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.applyLocalizedSearchChrome()
            self?.applySearchFieldDirection()
            self?.reloadSearchResultsForCurrentLanguage()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    private func applyLocalizedSearchChrome() {
        searchScreenTitleLabel.text = AppL10n.t(.searchTitle)
        searchTextfield.placeholder = AppL10n.t(.searchPlaceholder)
        searchMicPlaceholderField.placeholder = AppL10n.t(.searchShortPlaceholder)
        let rtl = LanguageManager.shared.isRTL()
        searchScreenTitleLabel.textAlignment = rtl ? .right : .natural
    }

    private func applySearchFieldDirection() {
        let rtl = LanguageManager.shared.isRTL()
        searchTextfield.textAlignment = rtl ? .right : .natural
        searchTextfield.semanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
    }

    private func reloadSearchResultsForCurrentLanguage() {
        let query = searchTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else {
            resultsTableView.reloadData()
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
            resultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        resultsTableView.separatorStyle = .none
        resultsTableView.backgroundColor = .clear
        resultsTableView.tableFooterView = UIView()
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        resultsTableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
    }
    
    @objc private func searchTextChanged() {
        let query = searchTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        searchWorkItem?.cancel()
        if query.isEmpty {
            results = []
            resultsTableView.reloadData()
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(query: query)
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }
    
    private func performSearch(query: String) {
        APIManager.shared.searchEpisodes(query: query) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self?.results = items
                    self?.resultsTableView.reloadData()
                case .failure(let error):
                    print("Search error: \(error)")
                    self?.results = []
                    self?.resultsTableView.reloadData()
                }
            }
        }
    }
    
    private func configureCell(_ cell: KidsStoriesTableViewCell, with item: SearchEpisode) {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        let translation = item.getTranslation(for: currentLanguage) ?? item.getTranslation(for: "en")
        cell.titleLbl.text = translation?.name ?? ""
        cell.textLbl.text = translation?.description ?? ""
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        
        let placeholder = UIImage(named: "placeholder")
        guard let imageUrl = item.thumbnailURL, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.mainImageView.image = placeholder
            return
        }
        
        cell.mainImageView.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground, .highPriority])
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
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KidsStoriesTableViewCell.reuseIdentifier, for: indexPath) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        
        configureCell(cell, with: results[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}
