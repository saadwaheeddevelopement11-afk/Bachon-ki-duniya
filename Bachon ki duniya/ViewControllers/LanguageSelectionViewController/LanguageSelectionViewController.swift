//
//  LanguageSelectionViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

import UIKit

class LanguageSelectionViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    private var languages: [Language] = []
    private var isLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        fetchLanguages()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
    }
    
    private func fetchLanguages() {
        isLoading = true
        loadingIndicator.startAnimating()
        
        APIManager.shared.fetchLanguages { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let languages):
                    self?.languages = languages
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to load languages: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.fetchLanguages()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension LanguageSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let language = languages[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = language.nativeName
        cell.detailTextLabel?.text = language.name
        
        // Checkmark for selected language
        let currentLanguageCode = LanguageManager.shared.currentLanguageCode
        if language.languageCode == currentLanguageCode {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        // Set text alignment based on language direction
        if language.direction == "RTL" {
            cell.textLabel?.textAlignment = .right
            cell.detailTextLabel?.textAlignment = .right
        } else {
            cell.textLabel?.textAlignment = .left
            cell.detailTextLabel?.textAlignment = .left
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LanguageSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedLanguage = languages[indexPath.row]
        let currentLanguageCode = LanguageManager.shared.currentLanguageCode
        
        // Only reload if language actually changed
        if selectedLanguage.languageCode != currentLanguageCode {
            // Save the selected language
            LanguageManager.shared.saveLanguage(selectedLanguage)
            
            // Show confirmation
            let alert = UIAlertController(
                title: "Language Changed",
                message: "The app language has been changed to \(selectedLanguage.nativeName). The content will reload.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                // Notify to reload home screen
                NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
}
