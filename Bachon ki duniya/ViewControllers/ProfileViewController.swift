//
//  ProfileViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit

class ProfileViewController: UIViewController {

    @IBOutlet weak var yourReportTitleLabel: UILabel!
    @IBOutlet weak var totalWatchTimeTitleLabel: UILabel!
    @IBOutlet weak var totalWatchTimeValueLabel: UILabel!
    @IBOutlet weak var mostWatchedCategoryTitleLabel: UILabel!
    @IBOutlet weak var mostWatchedCategoryValueLabel: UILabel!
    @IBOutlet weak var parentalControlsLabel: UILabel!
    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet weak var profileSelectLanguageRowLabel: UILabel!
    @IBOutlet weak var faqsLabel: UILabel!
    @IBOutlet weak var termsOfServiceLabel: UILabel!
    @IBOutlet weak var selectedLanguageLbl: UILabel!

    private var languageObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        applyLocalizedProfileChrome()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.applyLocalizedProfileChrome()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelectedLanguageLabel()
    }

    deinit {
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
    }

    private func updateSelectedLanguageLabel() {
        let name = LanguageManager.shared.currentLanguageName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let code = LanguageManager.shared.currentLanguageCode
        if let name, !name.isEmpty {
            selectedLanguageLbl.text = name
        } else {
            selectedLanguageLbl.text = code.uppercased()
        }
    }

    private func applyLocalizedProfileChrome() {
        yourReportTitleLabel.text = AppL10n.t(.profileYourReport)
        totalWatchTimeTitleLabel.text = AppL10n.t(.profileTotalWatchTime)
        totalWatchTimeValueLabel.text = AppL10n.t(.profileWatchTimeSample)
        mostWatchedCategoryTitleLabel.text = AppL10n.t(.profileMostWatchedCategory)
        mostWatchedCategoryValueLabel.text = AppL10n.t(.profileSampleCategoryName)
        parentalControlsLabel.text = AppL10n.t(.profileParentalControls)
        notificationsLabel.text = AppL10n.t(.profileNotifications)
        profileSelectLanguageRowLabel.text = AppL10n.t(.profileSelectLanguage)
        faqsLabel.text = AppL10n.t(.profileFAQs)
        termsOfServiceLabel.text = AppL10n.t(.profileTermsOfService)
        updateSelectedLanguageLabel()

        let rtl = LanguageManager.shared.isRTL()
        let align: NSTextAlignment = rtl ? .right : .natural
        [yourReportTitleLabel, totalWatchTimeTitleLabel, totalWatchTimeValueLabel,
         mostWatchedCategoryTitleLabel, mostWatchedCategoryValueLabel,
         parentalControlsLabel, notificationsLabel, profileSelectLanguageRowLabel,
         faqsLabel, termsOfServiceLabel, selectedLanguageLbl].forEach { $0?.textAlignment = align }
    }

    @IBAction func logoutBtn(_ sender: UIButton) {
        let alert = UIAlertController(
            title: AppL10n.t(.profileLogoutTitle),
            message: AppL10n.t(.profileLogoutMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: AppL10n.t(.profileLogoutAction), style: .destructive) { _ in
            UserDefaults.standard.set(false, forKey: AppDefaultsKeys.isLoggedIn)
            isLoggedIn = false
            AppRouter.setRoot(.login, animated: true)
        })
        present(alert, animated: true)
    }

    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            present(vc, animated: true)
        }
    }

    @IBAction func totalWatchTimeBtn(_ sender: UIButton) {}

    @IBAction func mostWatchedCatBtn(_ sender: UIButton) {}
}
