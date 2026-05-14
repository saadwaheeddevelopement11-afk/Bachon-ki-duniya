//
//  LanguageSelectionViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

import UIKit

class LanguageSelectionViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var crossButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    // MARK: - Properties
    private var languages: [Language] = []
    private var isLoading = false
    private var selectedLanguage: Language?
    private var originalLanguageCode: String
    private let languageBackgroundColorNames = ["blue", "purple", "yellow", "lightGreen", "pink", "green", "turquoise"]
    private let lightBackgroundColorNames: Set<String> = ["yellow", "lightGreen"]
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.originalLanguageCode = LanguageManager.shared.currentLanguageCode
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        self.originalLanguageCode = LanguageManager.shared.currentLanguageCode
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupGestures()
        fetchLanguages()
        NotificationCenter.default.addObserver(self, selector: #selector(appLanguageDidChange), name: .languageDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appLanguageDidChange() {
        applySheetCopy()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        // Set initial selected language
        selectedLanguage = languages.first(where: { $0.languageCode == originalLanguageCode })
        
        // Style the confirm button
        confirmButton.layer.cornerRadius = 8
        confirmButton.clipsToBounds = true
        
        // Style the cross button
        crossButton.tintColor = .darkGray
        
        // Make container view rounded corners
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        applySheetCopy()
    }

    private func applySheetCopy() {
        titleLabel.text = AppL10n.t(.languageSheetTitle)
        subtitleLabel.text = AppL10n.t(.languageSheetSubtitle)
        let rtl = LanguageManager.shared.isRTL()
        titleLabel.textAlignment = rtl ? .right : .natural
        subtitleLabel.textAlignment = rtl ? .right : .natural
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: "LanguagesTableViewCell", bundle: nil),
            forCellReuseIdentifier: "LanguagesTableViewCell"
        )
        tableView.allowsSelection = true
    }
    
    private func setupGestures() {
        // Add tap gesture to dismiss when tapping outside container
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // Add cross button action
        crossButton.addTarget(self, action: #selector(crossButtonTapped), for: .touchUpInside)
        
        // Add confirm button action
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            handleDismissal()
        }
    }
    
    @objc private func crossButtonTapped() {
        handleDismissal()
    }
    
    @objc private func confirmButtonTapped() {
        changeLanguage()
    }
    
    private func handleDismissal() {
        // Check if language was changed
        if let selected = selectedLanguage,
           selected.languageCode != originalLanguageCode {
            
            // Show confirmation alert
            let alertTitle = AppL10n.t(.changeLanguageTitle)
            let alertMessage = AppL10n.t(.changeLanguageMessageFormat, selected.nativeName)
            
            let alert = UIAlertController(
                title: alertTitle,
                message: alertMessage,
                preferredStyle: .alert
            )
            
            let changeTitle = AppL10n.t(.change)
            let cancelTitle = AppL10n.t(.cancel)
            
            alert.addAction(UIAlertAction(title: changeTitle, style: .default) { [weak self] _ in
                self?.changeLanguage()
            })
            
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { [weak self] _ in
                self?.dismissScreen()
            })
            
            present(alert, animated: true)
        } else {
            dismissScreen()
        }
    }
    
    private func changeLanguage() {
        guard let selected = selectedLanguage,
              selected.languageCode != originalLanguageCode else {
            dismissScreen()
            return
        }
        
        // Save the selected language
        LanguageManager.shared.saveLanguage(selected)
        
        // Notify to reload home screen
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        
        // Show success message before dismissing
        let successMessage = AppL10n.t(.languageChangedFormat, selected.nativeName)
        
        let alert = UIAlertController(
            title: AppL10n.t(.successTitle),
            message: successMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default) { [weak self] _ in
            self?.dismissScreen()
        })
        
        present(alert, animated: true)
    }
    
    private func dismissScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - API Calls
    private func fetchLanguages() {
        isLoading = true
//        loadingIndicator.startAnimating()
        confirmButton.isEnabled = false
        
        APIManager.shared.fetchLanguages { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
//                self?.loadingIndicator.stopAnimating()
                self?.confirmButton.isEnabled = true
                
                switch result {
                case .success(let languages):
                    self?.languages = languages
                    // Set initial selected language
                    if let currentLanguage = languages.first(where: { $0.languageCode == self?.originalLanguageCode }) {
                        self?.selectedLanguage = currentLanguage
                    } else if let firstLanguage = languages.first {
                        self?.selectedLanguage = firstLanguage
                    }
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: AppL10n.t(.errorTitle),
            message: AppL10n.t(.failedToLoadLanguagesFormat, error.localizedDescription),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppL10n.t(.retry), style: .default) { [weak self] _ in
            self?.fetchLanguages()
        })
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel) { [weak self] _ in
            self?.dismissScreen()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension LanguageSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LanguagesTableViewCell", for: indexPath) as? LanguagesTableViewCell else {
            return UITableViewCell()}
        
        let language = languages[indexPath.row]
        
        // Configure label with API value
        cell.languageName.text = language.nativeName
        
        let colorName = languageBackgroundColorNames[indexPath.row % languageBackgroundColorNames.count]
        let bgColor = UIColor(named: colorName) ?? .systemGray5
        
        let useDarkSelectedText = lightBackgroundColorNames.contains(colorName)
        // Selected state with high-contrast text + shadow
        let isSelectedLanguage = selectedLanguage?.languageCode == language.languageCode
        cell.configure(backgroundColor: bgColor, isSelected: isSelectedLanguage, useDarkSelectedText: useDarkSelectedText)
        
        // Set text alignment based on language direction
        if language.direction == "RTL" {
            cell.languageName.textAlignment = .right
        } else {
            cell.languageName.textAlignment = .left
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.bounds.height / 7
    }
}

// MARK: - UITableViewDelegate
extension LanguageSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selected = languages[indexPath.row]
        let previousSelectedCode = selectedLanguage?.languageCode
        selectedLanguage = selected

        var rowsToReload: [IndexPath] = [indexPath]
        if let previousCode = previousSelectedCode,
           let previousIndex = languages.firstIndex(where: { $0.languageCode == previousCode }),
           previousIndex != indexPath.row {
            rowsToReload.append(IndexPath(row: previousIndex, section: 0))
        }

        UIView.performWithoutAnimation {
            tableView.reloadRows(at: rowsToReload, with: .none)
        }
    }
}
