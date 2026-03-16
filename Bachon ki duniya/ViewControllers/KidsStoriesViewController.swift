//
//  KidsStoriesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class KidsStoriesViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    
    // Temporary dummy data so the table shows some rows
    private let stories = Array(repeating: "Story", count: 10)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 120
        
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableview.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
        tableview.tableFooterView = UIView()
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension KidsStoriesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        stories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        return cell
    }
}

extension KidsStoriesViewController: UITableViewDelegate {}
