//
//  LearnNMoreViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit

class LearnNMoreViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private var latestCategories: [LatestEpisodeCategory] = []
    private var languageObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchLatestEpisodes()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.fetchLatestEpisodes()
        }
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = 104
        tableView.register(UINib(nibName: "LibraryTblViewCell", bundle: nil), forCellReuseIdentifier: "LibraryTblViewCell")
    }

    private func fetchLatestEpisodes() {
        let languageCode = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchLatestEpisodes(languageCode: languageCode) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    self?.latestCategories = categories
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Failed to fetch latest episodes: \(error)")
                }
            }
        }
    }
}

extension LearnNMoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        latestCategories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LibraryTblViewCell", for: indexPath) as? LibraryTblViewCell else {
            return UITableViewCell()
        }
        let category = latestCategories[indexPath.row]
        cell.configure(title: category.categoryName, episodes: category.episodes)
        cell.onSelectEpisode = { [weak self] episode in
            guard let self else { return }
            guard let url = episode.videoURL, !url.isEmpty else { return }
            VideoPlaybackPresenter.play(urlString: url, from: self)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        150
    }
}
