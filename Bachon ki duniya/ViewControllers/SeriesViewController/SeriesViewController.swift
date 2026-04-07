//
//  SeriesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 07/04/2026.
//

import UIKit

class SeriesViewController: UIViewController {
    
    var categoryId = 0
    var categoryTitle = "Series"
    
    @IBOutlet weak var tableView: UITableView!
    
    private var seriesItems: [SeriesItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = categoryTitle
        setupTableView()
        fetchSeries()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
    }
    
    private func fetchSeries() {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchSeries(categoryId: categoryId, languageCode: currentLanguage) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self?.seriesItems = items
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Error fetching series: \(error)")
                }
            }
        }
    }
    
    private func configureSeriesCell(_ cell: KidsStoriesTableViewCell, item: SeriesItem) {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        let translation = item.getTranslation(for: currentLanguage) ?? item.getTranslation(for: "en")
        
        cell.titleLbl.text = translation?.name ?? ""
        cell.textLbl.text = translation?.description ?? ""
        cell.titleLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        cell.textLbl.textAlignment = LanguageManager.shared.isRTL() ? .right : .left
        
        guard let imageUrl = item.img, !imageUrl.isEmpty, let url = URL(string: imageUrl) else {
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
}

extension SeriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seriesItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KidsStoriesTableViewCell.reuseIdentifier, for: indexPath) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        
        let item = seriesItems[indexPath.row]
        configureSeriesCell(cell, item: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedSeries = seriesItems[indexPath.row]
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        let selectedTitle = selectedSeries.getTranslation(for: currentLanguage)?.name ??
            selectedSeries.getTranslation(for: "en")?.name ??
            "Stories"
        
        if let storiesVC = storyboard?.instantiateViewController(withIdentifier: "StoriesViewController") as? StoriesViewController {
            storiesVC.seriesId = selectedSeries.id
            storiesVC.seriesTitle = selectedTitle
            navigationController?.pushViewController(storiesVC, animated: true)
        }
    }
}
