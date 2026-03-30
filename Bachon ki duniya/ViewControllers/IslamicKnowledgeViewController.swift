//
//  IslamicKnowledgeViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 11/03/2026.
//

import UIKit

class IslamicKnowledgeViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    
    private let items = Array(repeating: "Item", count: 10)
    
    var categoryId = 0
    var categoryTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 100
        tableview.separatorStyle = .none
        let nib = UINib(nibName: "IslamicKnowledgeTableViewCell", bundle: nil)
        tableview.register(nib, forCellReuseIdentifier: "IslamicKnowledgeTableViewCell")
        tableview.tableFooterView = UIView()
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension IslamicKnowledgeViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "IslamicKnowledgeTableViewCell", for: indexPath) as? IslamicKnowledgeTableViewCell else {
            return UITableViewCell()
        }
        cell.topicimageView.image = UIImage(named: "islamicKnowledgeImage")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}

extension IslamicKnowledgeViewController: UITableViewDelegate {}

