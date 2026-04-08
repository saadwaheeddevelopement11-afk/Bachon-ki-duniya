//
//  StoriesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 07/04/2026.
//

import UIKit

class StoriesViewController: UIViewController {
    
    var seriesId = 0
    var seriesTitle = "Stories"
    
    @IBOutlet weak var seriesTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    private var episodes: [StoryEpisode] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = seriesTitle
        seriesTitleLabel.text = seriesTitle
        setupTableView()
        fetchEpisodes()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
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
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching episodes for series: \(error)")
                }
            }
        }
    }
    
    private func configureEpisodeCell(_ cell: KidsStoriesTableViewCell, episode: StoryEpisode) {
        cell.titleLbl.text = episode.title
        cell.textLbl.text = episode.description
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        
        guard let imageUrl = episode.thumbnailURL, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
            cell.mainImageView.image = UIImage(named: "placeholder")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                cell.mainImageView.image = image
            }
        }.resume()
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
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
