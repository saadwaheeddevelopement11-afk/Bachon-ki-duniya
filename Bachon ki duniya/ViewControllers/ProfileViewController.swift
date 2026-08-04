import PhotosUI
import UIKit
import SDWebImage

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
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileEditBadgeView: UIView!
    @IBOutlet weak var profileNameLabel: UILabel!

    private var languageObserver: NSObjectProtocol?
    private var screenTimeObserver: NSObjectProtocol?
    private var profileObserver: NSObjectProtocol?
    private var screenTimeRefreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageEditing()
        reloadProfileImage()
        applyLocalizedProfileChrome()
        wireExtraTaps()
        languageObserver = NotificationCenter.default.addObserver(forName: .languageDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.applyLocalizedProfileChrome()
        }
        screenTimeObserver = NotificationCenter.default.addObserver(forName: .appScreenTimeDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updateScreenTimeSummary()
        }
        profileObserver = NotificationCenter.default.addObserver(forName: .userProfileDidChange, object: nil, queue: .main) { [weak self] _ in
            self?.updateProfileNameLabel()
            self?.reloadProfileImage()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSelectedLanguageLabel()
        updateProfileNameLabel()
        reloadProfileImage()
        updateScreenTimeSummary()
        updateContinueWatchingSummary()
        startScreenTimeRefreshTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScreenTimeRefreshTimer()
    }

    deinit {
        stopScreenTimeRefreshTimer()
        if let languageObserver {
            NotificationCenter.default.removeObserver(languageObserver)
        }
        if let screenTimeObserver {
            NotificationCenter.default.removeObserver(screenTimeObserver)
        }
        if let profileObserver {
            NotificationCenter.default.removeObserver(profileObserver)
        }
    }

    private func wireExtraTaps() {
        // Parental Controls row (storyboard: label → view → HStack → HStack → row container).
        if let row = parentalControlsLabel?.superview?.superview?.superview?.superview {
            row.isUserInteractionEnabled = true
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openParentalControls)))
        }

        // "See All" chip next to Your Report → parental report screen.
        DispatchQueue.main.async { [weak self] in
            guard let self, let seeAllLabel = self.findSeeAllLabel() else { return }
            let chip = seeAllLabel.superview ?? seeAllLabel
            chip.isUserInteractionEnabled = true
            chip.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.openParentalControls)))
        }
    }

    private func findSeeAllLabel() -> UILabel? {
        findLabel(in: view) { label in
            let t = label.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            return t == "see all" || t == AppL10n.t(.profileSeeAll).lowercased()
        }
    }

    private func findLabel(in root: UIView, where predicate: (UILabel) -> Bool) -> UILabel? {
        if let label = root as? UILabel, predicate(label) { return label }
        for child in root.subviews {
            if let found = findLabel(in: child, where: predicate) { return found }
        }
        return nil
    }

    private func setupProfileImageEditing() {
        profileImageView?.contentMode = .scaleAspectFill
        profileImageView?.clipsToBounds = true
        profileImageView?.isUserInteractionEnabled = true

        let imageTap = UITapGestureRecognizer(target: self, action: #selector(editProfileImageTapped))
        profileImageView?.addGestureRecognizer(imageTap)

        profileEditBadgeView?.isUserInteractionEnabled = true
        let badgeTap = UITapGestureRecognizer(target: self, action: #selector(editProfileImageTapped))
        profileEditBadgeView?.addGestureRecognizer(badgeTap)

        // Larger hit area around the small pencil badge.
        profileEditBadgeView?.superview?.isUserInteractionEnabled = true
    }

    private func reloadProfileImage() {
        if let saved = ProfileAvatarStore.load() {
            profileImageView?.sd_cancelCurrentImageLoad()
            profileImageView?.image = saved
            return
        }
        if let url = UserProfileStore.current?.imageURL {
            let placeholder = UIImage(named: "profileImage")
            profileImageView?.sd_setImage(with: url, placeholderImage: placeholder, options: [.retryFailed, .continueInBackground])
            return
        }
        profileImageView?.sd_cancelCurrentImageLoad()
        profileImageView?.image = UIImage(named: "profileImage")
    }

    @objc private func editProfileImageTapped() {
        let sheet = UIAlertController(
            title: AppL10n.t(.profileChangePhotoTitle),
            message: nil,
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: AppL10n.t(.profileChooseFromLibrary), style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        })
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: AppL10n.t(.profileTakePhoto), style: .default) { [weak self] _ in
                self?.presentCamera()
            })
        }
        if ProfileAvatarStore.load() != nil {
            sheet.addAction(UIAlertAction(title: AppL10n.t(.profileRemovePhoto), style: .destructive) { [weak self] _ in
                ProfileAvatarStore.clear()
                self?.reloadProfileImage()
            })
        }
        sheet.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = profileEditBadgeView ?? profileImageView
            popover.sourceRect = (profileEditBadgeView ?? profileImageView)?.bounds ?? .zero
        }
        present(sheet, animated: true)
    }

    private func presentPhotoLibrary() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    private func applySelectedImage(_ image: UIImage) {
        if ProfileAvatarStore.save(image) {
            profileImageView?.image = image
        } else {
            let alert = UIAlertController(
                title: AppL10n.t(.errorTitle),
                message: AppL10n.t(.profilePhotoSaveFailed),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
            present(alert, animated: true)
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

    private func updateProfileNameLabel() {
        let text = UserSession.profileDisplayText
        profileNameLabel?.text = text.isEmpty ? "—" : text
    }

    private func updateScreenTimeSummary() {
        // Same app foreground / screen-time total shown on the Screen Time screen.
        totalWatchTimeValueLabel?.text = AppScreenTimeTracker.shared.formattedTotal()
    }

    private func startScreenTimeRefreshTimer() {
        stopScreenTimeRefreshTimer()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateScreenTimeSummary()
        }
        RunLoop.main.add(timer, forMode: .common)
        screenTimeRefreshTimer = timer
    }

    private func stopScreenTimeRefreshTimer() {
        screenTimeRefreshTimer?.invalidate()
        screenTimeRefreshTimer = nil
    }

    private func updateContinueWatchingSummary() {
        ContinueWatchingStore.fetchForHome(limit: 1) { [weak self] records in
            guard let self else { return }
            if let first = records.first, let title = first.title, !title.isEmpty {
                self.mostWatchedCategoryValueLabel?.text = title
            } else if !records.isEmpty {
                self.mostWatchedCategoryValueLabel?.text = AppL10n.t(.homeContinueWatching)
            } else {
                self.mostWatchedCategoryValueLabel?.text = AppL10n.t(.profileSampleCategoryName)
            }
        }
    }

    private func applyLocalizedProfileChrome() {
        yourReportTitleLabel.text = AppL10n.t(.profileYourReport)
        totalWatchTimeTitleLabel.text = AppL10n.t(.profileTotalWatchTime)
        mostWatchedCategoryTitleLabel.text = AppL10n.t(.profileMostWatchedCategory)
        parentalControlsLabel.text = AppL10n.t(.profileParentalControls)
        notificationsLabel.text = AppL10n.t(.profileNotifications)
        profileSelectLanguageRowLabel.text = AppL10n.t(.profileSelectLanguage)
        faqsLabel.text = AppL10n.t(.profileFAQs)
        termsOfServiceLabel.text = AppL10n.t(.profileTermsOfService)
        updateSelectedLanguageLabel()
        updateProfileNameLabel()
        updateScreenTimeSummary()
        updateContinueWatchingSummary()

        if let seeAll = findSeeAllLabel() {
            seeAll.text = AppL10n.t(.profileSeeAll)
        }

        let rtl = LanguageManager.shared.isRTL()
        let align: NSTextAlignment = rtl ? .right : .natural
        [yourReportTitleLabel, totalWatchTimeTitleLabel, totalWatchTimeValueLabel,
         mostWatchedCategoryTitleLabel, mostWatchedCategoryValueLabel,
         parentalControlsLabel, notificationsLabel, profileSelectLanguageRowLabel,
         faqsLabel, termsOfServiceLabel, selectedLanguageLbl, profileNameLabel].forEach { $0?.textAlignment = align }
        // Name pill stays centered in its container.
        profileNameLabel?.textAlignment = .center
    }

    private func pushFromProfile(_ viewController: UIViewController) {
        viewController.hidesBottomBarWhenPushed = true
        if let nav = navigationController {
            nav.pushViewController(viewController, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: viewController)
            nav.isNavigationBarHidden = true
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    @objc private func openParentalControls() {
        pushFromProfile(ParentalControlViewController())
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
            UserSession.clearMsisdn()
            AppRouter.setRoot(.login, animated: true)
        })
        present(alert, animated: true)
    }

    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            present(vc, animated: true)
        }
    }

    @IBAction func totalWatchTimeBtn(_ sender: UIButton) {
        pushFromProfile(ScreenTimeViewController())
    }

    @IBAction func mostWatchedCatBtn(_ sender: UIButton) {
        pushFromProfile(ContinueWatchingListViewController())
    }
}

// MARK: - PHPicker

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                if let error {
                    let alert = UIAlertController(
                        title: AppL10n.t(.errorTitle),
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
                    self?.present(alert, animated: true)
                    return
                }
                guard let image = object as? UIImage else { return }
                self?.applySelectedImage(image)
            }
        }
    }
}

// MARK: - Camera

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else { return }
        applySelectedImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
