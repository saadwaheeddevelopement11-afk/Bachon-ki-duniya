//
//  HadeesViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 13/03/2026.
//

import UIKit

class AhadeesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 120
        
        let nib = UINib(nibName: "KidsStoriesTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: KidsStoriesTableViewCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
    }
    
    @IBAction func backButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension AhadeesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: KidsStoriesTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? KidsStoriesTableViewCell else {
            return UITableViewCell()
        }
        cell.mainImageView.image = UIImage(named: "testimage")
        cell.titleLbl.text = "Whoever believes in Allah and the last day should..."
        cell.textLbl.text = "- Sahih Al Bukhari 6136"
        return cell
    }
}

extension AhadeesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("indexPath: \(indexPath.row)")
    }
}

