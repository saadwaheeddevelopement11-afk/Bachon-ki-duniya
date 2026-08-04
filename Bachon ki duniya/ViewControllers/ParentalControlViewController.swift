import UIKit

fileprivate enum ParentalPalette {
    static let accent = UIColor(red: 0.93, green: 0.22, blue: 0.40, alpha: 1)
    static let title = UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1)
    static let secondary = UIColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1)
    static let cardBorder = UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1)
    static let track = UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1)
}

/// Parental controls: setup / verify PIN gate, then dashboard with limit + category locks.
final class ParentalControlViewController: UIViewController {

    private enum Mode {
        case loading
        case setup
        case verify
        case dashboard
        case changePIN
        case resetRequest
        case resetConfirm
    }

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let spinner = UIActivityIndicatorView(style: .large)

    private var mode: Mode = .loading
    private var status: ParentalStatusData?
    private var categories: [(id: Int, title: String)] = []
    private var verifiedSessionPIN: String?

    // Shared fields reused across modes
    private let pinField = UITextField()
    private let confirmPinField = UITextField()
    private let newPinField = UITextField()
    private let limitSlider = UISlider()
    private let limitValueLabel = UILabel()
    private let todayValueLabel = UILabel()
    private let todayProgressFill = UIView()
    private var todayProgressWidth: NSLayoutConstraint?
    private let otpField = UITextField()
    private let primaryButton = UIButton(type: .system)
    private let secondaryButton = UIButton(type: .system)
    private let categoriesStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupHeader()
        setupScroll()
        setupSpinner()
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditingTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        bootstrap()
    }

    // MARK: - Bootstrap

    private func bootstrap() {
        guard UserSession.msisdnDigits != nil else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalNeedPhone)) { [weak self] in
                self?.backTapped()
            }
            return
        }
        setMode(.loading)
        ParentalStatusStore.refreshInBackground { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let status):
                    self.status = status
                    if status.isEnabled {
                        self.setMode(.verify)
                    } else {
                        self.setMode(.setup)
                    }
                case .failure:
                    // No prior status — treat as needs setup.
                    self.status = nil
                    self.setMode(.setup)
                }
            }
        }
    }

    private func setMode(_ mode: Mode) {
        self.mode = mode
        rebuildContent()
    }

    // MARK: - Chrome

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .white

        backButton.translatesAutoresizingMaskIntoConstraints = false
        if let img = UIImage(named: "backIcon") {
            backButton.setImage(img.withRenderingMode(.alwaysOriginal), for: .normal)
        } else {
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            backButton.tintColor = ParentalPalette.title
        }
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = AppL10n.t(.profileParentalControls)
        titleLabel.font = UIFont(name: "Poppins-SemiBold", size: 20) ?? .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = ParentalPalette.title

        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -16)
        ])
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 40, right: 16)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func rebuildContent() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        spinner.stopAnimating()
        scrollView.isHidden = mode == .loading

        switch mode {
        case .loading:
            spinner.startAnimating()
        case .setup:
            titleLabel.text = AppL10n.t(.parentalSetupTitle)
            buildSetupUI()
        case .verify:
            titleLabel.text = AppL10n.t(.parentalVerifyTitle)
            buildVerifyUI()
        case .dashboard:
            titleLabel.text = AppL10n.t(.profileParentalControls)
            buildDashboardUI()
            loadCategoriesIfNeeded()
        case .changePIN:
            titleLabel.text = AppL10n.t(.parentalChangePIN)
            buildChangePINUI()
        case .resetRequest:
            titleLabel.text = AppL10n.t(.parentalResetPINTitle)
            buildResetRequestUI()
        case .resetConfirm:
            titleLabel.text = AppL10n.t(.parentalResetPINTitle)
            buildResetConfirmUI()
        }
    }

    // MARK: - UI builders

    private func styleCard(_ card: UIView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = ParentalPalette.cardBorder.cgColor
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont(name: "Poppins-SemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = ParentalPalette.title
        return label
    }

    private func configurePINField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.textAlignment = .center
        field.keyboardType = .numberPad
        field.isSecureTextEntry = true
        field.font = UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1.5
        field.layer.borderColor = ParentalPalette.accent.cgColor
        field.backgroundColor = .white
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.text = nil
    }

    private func configurePrimaryButton(_ title: String, action: Selector) {
        primaryButton.setTitle(title, for: .normal)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        primaryButton.backgroundColor = ParentalPalette.accent
        primaryButton.layer.cornerRadius = 14
        primaryButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        primaryButton.removeTarget(nil, action: nil, for: .allEvents)
        primaryButton.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureSecondaryButton(_ title: String, action: Selector) {
        secondaryButton.setTitle(title, for: .normal)
        secondaryButton.setTitleColor(ParentalPalette.accent, for: .normal)
        secondaryButton.titleLabel?.font = UIFont(name: "Poppins-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        secondaryButton.backgroundColor = .clear
        secondaryButton.removeTarget(nil, action: nil, for: .allEvents)
        secondaryButton.addTarget(self, action: action, for: .touchUpInside)
    }

    private func buildSetupUI() {
        let card = UIView()
        styleCard(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        let info = UILabel()
        info.text = AppL10n.t(.parentalSetupHint)
        info.numberOfLines = 0
        info.font = UIFont(name: "Poppins-Regular", size: 13) ?? .systemFont(ofSize: 13)
        info.textColor = ParentalPalette.secondary

        configurePINField(pinField, placeholder: AppL10n.t(.parentalCreatePIN))
        configurePINField(confirmPinField, placeholder: AppL10n.t(.parentalConfirmPIN))

        limitSlider.minimumValue = 0
        limitSlider.maximumValue = 180
        limitSlider.value = 60
        limitSlider.minimumTrackTintColor = ParentalPalette.accent
        limitSlider.maximumTrackTintColor = ParentalPalette.track
        limitSlider.addTarget(self, action: #selector(limitChanged), for: .valueChanged)
        limitValueLabel.font = UIFont(name: "Poppins-SemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        limitValueLabel.textColor = ParentalPalette.accent
        limitValueLabel.textAlignment = .center
        updateLimitLabel()

        configurePrimaryButton(AppL10n.t(.parentalEnable), action: #selector(setupTapped))

        stack.addArrangedSubview(info)
        stack.addArrangedSubview(makeSectionTitle(AppL10n.t(.parentalEnterPIN)))
        stack.addArrangedSubview(pinField)
        stack.addArrangedSubview(confirmPinField)
        stack.addArrangedSubview(makeSectionTitle(AppL10n.t(.parentalDailyLimit)))
        stack.addArrangedSubview(limitSlider)
        stack.addArrangedSubview(limitValueLabel)
        stack.addArrangedSubview(primaryButton)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func buildVerifyUI() {
        let card = UIView()
        styleCard(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        let info = UILabel()
        info.text = AppL10n.t(.parentalVerifyHint)
        info.numberOfLines = 0
        info.font = UIFont(name: "Poppins-Regular", size: 13) ?? .systemFont(ofSize: 13)
        info.textColor = ParentalPalette.secondary

        configurePINField(pinField, placeholder: AppL10n.t(.parentalEnterPIN))
        configurePrimaryButton(AppL10n.t(.parentalUnlock), action: #selector(verifyTapped))
        configureSecondaryButton(AppL10n.t(.parentalForgotPIN), action: #selector(forgotPINTapped))

        stack.addArrangedSubview(info)
        stack.addArrangedSubview(pinField)
        stack.addArrangedSubview(primaryButton)
        stack.addArrangedSubview(secondaryButton)

        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func buildDashboardUI() {
        // Today usage
        let todayCard = UIView()
        styleCard(todayCard)
        let todayStack = UIStackView()
        todayStack.axis = .vertical
        todayStack.spacing = 10
        todayStack.translatesAutoresizingMaskIntoConstraints = false
        todayStack.isLayoutMarginsRelativeArrangement = true
        todayStack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        todayValueLabel.font = UIFont(name: "Poppins-SemiBold", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        todayValueLabel.textColor = ParentalPalette.accent

        let track = UIView()
        track.backgroundColor = ParentalPalette.track
        track.layer.cornerRadius = 4
        track.clipsToBounds = true
        track.translatesAutoresizingMaskIntoConstraints = false
        track.heightAnchor.constraint(equalToConstant: 8).isActive = true
        todayProgressFill.translatesAutoresizingMaskIntoConstraints = false
        todayProgressFill.backgroundColor = ParentalPalette.accent
        todayProgressFill.layer.cornerRadius = 4
        track.addSubview(todayProgressFill)
        todayProgressWidth = todayProgressFill.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            todayProgressFill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            todayProgressFill.topAnchor.constraint(equalTo: track.topAnchor),
            todayProgressFill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            todayProgressWidth!
        ])

        todayStack.addArrangedSubview(makeSectionTitle(AppL10n.t(.parentalTodayUsage)))
        todayStack.addArrangedSubview(todayValueLabel)
        todayStack.addArrangedSubview(track)
        todayCard.addSubview(todayStack)
        NSLayoutConstraint.activate([
            todayStack.topAnchor.constraint(equalTo: todayCard.topAnchor),
            todayStack.leadingAnchor.constraint(equalTo: todayCard.leadingAnchor),
            todayStack.trailingAnchor.constraint(equalTo: todayCard.trailingAnchor),
            todayStack.bottomAnchor.constraint(equalTo: todayCard.bottomAnchor)
        ])
        contentStack.addArrangedSubview(todayCard)
        applyStatusToTodayUI()

        // Limit + update
        let limitCard = UIView()
        styleCard(limitCard)
        let limitStack = UIStackView()
        limitStack.axis = .vertical
        limitStack.spacing = 12
        limitStack.translatesAutoresizingMaskIntoConstraints = false
        limitStack.isLayoutMarginsRelativeArrangement = true
        limitStack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        limitSlider.minimumValue = 0
        limitSlider.maximumValue = 180
        limitSlider.value = Float(status?.dailyLimitMinutes ?? 60)
        limitSlider.minimumTrackTintColor = ParentalPalette.accent
        limitSlider.maximumTrackTintColor = ParentalPalette.track
        limitSlider.addTarget(self, action: #selector(limitChanged), for: .valueChanged)
        limitValueLabel.font = UIFont(name: "Poppins-SemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        limitValueLabel.textColor = ParentalPalette.accent
        limitValueLabel.textAlignment = .center
        updateLimitLabel()

        configurePrimaryButton(AppL10n.t(.parentalUpdateLimit), action: #selector(updateLimitTapped))

        limitStack.addArrangedSubview(makeSectionTitle(AppL10n.t(.parentalDailyLimit)))
        limitStack.addArrangedSubview(limitSlider)
        limitStack.addArrangedSubview(limitValueLabel)
        limitStack.addArrangedSubview(primaryButton)
        limitCard.addSubview(limitStack)
        NSLayoutConstraint.activate([
            limitStack.topAnchor.constraint(equalTo: limitCard.topAnchor),
            limitStack.leadingAnchor.constraint(equalTo: limitCard.leadingAnchor),
            limitStack.trailingAnchor.constraint(equalTo: limitCard.trailingAnchor),
            limitStack.bottomAnchor.constraint(equalTo: limitCard.bottomAnchor)
        ])
        contentStack.addArrangedSubview(limitCard)

        // Categories
        let catCard = UIView()
        styleCard(catCard)
        let catOuter = UIStackView()
        catOuter.axis = .vertical
        catOuter.spacing = 10
        catOuter.translatesAutoresizingMaskIntoConstraints = false
        catOuter.isLayoutMarginsRelativeArrangement = true
        catOuter.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        categoriesStack.axis = .vertical
        categoriesStack.spacing = 8

        catOuter.addArrangedSubview(makeSectionTitle(AppL10n.t(.parentalLockedCategories)))
        let hint = UILabel()
        hint.text = AppL10n.t(.parentalLockHint)
        hint.numberOfLines = 0
        hint.font = UIFont(name: "Poppins-Regular", size: 12) ?? .systemFont(ofSize: 12)
        hint.textColor = ParentalPalette.secondary
        catOuter.addArrangedSubview(hint)
        catOuter.addArrangedSubview(categoriesStack)
        catCard.addSubview(catOuter)
        NSLayoutConstraint.activate([
            catOuter.topAnchor.constraint(equalTo: catCard.topAnchor),
            catOuter.leadingAnchor.constraint(equalTo: catCard.leadingAnchor),
            catOuter.trailingAnchor.constraint(equalTo: catCard.trailingAnchor),
            catOuter.bottomAnchor.constraint(equalTo: catCard.bottomAnchor)
        ])
        contentStack.addArrangedSubview(catCard)
        rebuildCategoryRows()

        // Change PIN
        let changePINBtn = UIButton(type: .system)
        changePINBtn.setTitle(AppL10n.t(.parentalChangePIN), for: .normal)
        changePINBtn.setTitleColor(ParentalPalette.accent, for: .normal)
        changePINBtn.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        changePINBtn.backgroundColor = ParentalPalette.accent.withAlphaComponent(0.12)
        changePINBtn.layer.cornerRadius = 14
        changePINBtn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        changePINBtn.addTarget(self, action: #selector(changePINTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(changePINBtn)

        // Disable
        let disableBtn = UIButton(type: .system)
        disableBtn.setTitle(AppL10n.t(.parentalDisable), for: .normal)
        disableBtn.setTitleColor(.white, for: .normal)
        disableBtn.backgroundColor = UIColor(red: 0.75, green: 0.15, blue: 0.2, alpha: 1)
        disableBtn.titleLabel?.font = UIFont(name: "Poppins-SemiBold", size: 16) ?? .systemFont(ofSize: 16, weight: .semibold)
        disableBtn.layer.cornerRadius = 14
        disableBtn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        disableBtn.addTarget(self, action: #selector(disableTapped), for: .touchUpInside)
        contentStack.addArrangedSubview(disableBtn)

        configureSecondaryButton(AppL10n.t(.parentalForgotPIN), action: #selector(forgotPINTapped))
        contentStack.addArrangedSubview(secondaryButton)
    }

    private func buildChangePINUI() {
        let card = UIView()
        styleCard(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        let info = UILabel()
        info.text = AppL10n.t(.parentalChangePINHint)
        info.numberOfLines = 0
        info.font = UIFont(name: "Poppins-Regular", size: 13) ?? .systemFont(ofSize: 13)
        info.textColor = ParentalPalette.secondary

        configurePINField(pinField, placeholder: AppL10n.t(.parentalCurrentPIN))
        configurePINField(newPinField, placeholder: AppL10n.t(.parentalCreatePIN))
        configurePINField(confirmPinField, placeholder: AppL10n.t(.parentalConfirmPIN))
        configurePrimaryButton(AppL10n.t(.parentalSaveNewPIN), action: #selector(saveChangePINTapped))

        stack.addArrangedSubview(info)
        stack.addArrangedSubview(pinField)
        stack.addArrangedSubview(newPinField)
        stack.addArrangedSubview(confirmPinField)
        stack.addArrangedSubview(primaryButton)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func buildResetRequestUI() {
        let card = UIView()
        styleCard(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        let info = UILabel()
        info.text = AppL10n.t(.parentalResetHint)
        info.numberOfLines = 0
        info.font = UIFont(name: "Poppins-Regular", size: 13) ?? .systemFont(ofSize: 13)
        info.textColor = ParentalPalette.secondary

        configurePrimaryButton(AppL10n.t(.parentalSendOTP), action: #selector(requestResetOTPTapped))
        stack.addArrangedSubview(info)
        stack.addArrangedSubview(primaryButton)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func buildResetConfirmUI() {
        let card = UIView()
        styleCard(card)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14)

        otpField.placeholder = AppL10n.t(.parentalEnterOTP)
        otpField.textAlignment = .center
        otpField.keyboardType = .numberPad
        otpField.isSecureTextEntry = false
        otpField.font = UIFont(name: "Poppins-Regular", size: 16) ?? .systemFont(ofSize: 16)
        otpField.layer.cornerRadius = 12
        otpField.layer.borderWidth = 1.5
        otpField.layer.borderColor = ParentalPalette.accent.cgColor
        otpField.heightAnchor.constraint(equalToConstant: 48).isActive = true

        configurePINField(newPinField, placeholder: AppL10n.t(.parentalCreatePIN))
        configurePINField(confirmPinField, placeholder: AppL10n.t(.parentalConfirmPIN))
        configurePrimaryButton(AppL10n.t(.parentalConfirmReset), action: #selector(confirmResetTapped))

        stack.addArrangedSubview(otpField)
        stack.addArrangedSubview(newPinField)
        stack.addArrangedSubview(confirmPinField)
        stack.addArrangedSubview(primaryButton)
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        contentStack.addArrangedSubview(card)
    }

    private func applyStatusToTodayUI() {
        let used = status?.minutesUsedToday ?? 0
        let limit = status?.dailyLimitMinutes ?? 0
        if limit <= 0 {
            todayValueLabel.text = "\(used) min"
            todayProgressWidth?.isActive = false
            todayProgressWidth = todayProgressFill.widthAnchor.constraint(equalToConstant: 0)
            todayProgressWidth?.isActive = true
        } else if let track = todayProgressFill.superview {
            todayValueLabel.text = "\(used) min / \(limit) min"
            let ratio = min(1, CGFloat(used) / CGFloat(limit))
            todayProgressWidth?.isActive = false
            todayProgressWidth = todayProgressFill.widthAnchor.constraint(
                equalTo: track.widthAnchor,
                multiplier: max(0.02, ratio)
            )
            todayProgressWidth?.isActive = true
        } else {
            todayValueLabel.text = "\(used) min / \(limit) min"
        }
    }

    @objc private func limitChanged() {
        updateLimitLabel()
    }

    private func updateLimitLabel() {
        let minutes = Int(limitSlider.value.rounded())
        if minutes <= 0 {
            limitValueLabel.text = AppL10n.t(.parentalNoLimit)
        } else {
            limitValueLabel.text = "\(minutes) \(AppL10n.t(.parentalMinutes))"
        }
    }

    // MARK: - Categories

    private func loadCategoriesIfNeeded() {
        guard categories.isEmpty else {
            rebuildCategoryRows()
            return
        }
        let lang = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchCategories(languageCode: lang) { [weak self] result in
            DispatchQueue.main.async {
                guard let self, self.mode == .dashboard else { return }
                if case .success(let cats) = result {
                    self.categories = cats.map { cat in
                        let title = cat.getTranslation(for: lang)?.name
                            ?? cat.getTranslation(for: "en")?.name
                            ?? "Category \(cat.id)"
                        return (cat.id, title)
                    }
                }
                self.rebuildCategoryRows()
            }
        }
    }

    private func rebuildCategoryRows() {
        categoriesStack.arrangedSubviews.forEach {
            categoriesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let locked = Set(status?.lockedCategoryIds ?? [])
        if categories.isEmpty {
            let empty = UILabel()
            empty.text = AppL10n.t(.parentalNoCategories)
            empty.font = UIFont(name: "Poppins-Regular", size: 13) ?? .systemFont(ofSize: 13)
            empty.textColor = ParentalPalette.secondary
            categoriesStack.addArrangedSubview(empty)
            return
        }
        for item in categories {
            let row = makeCategoryRow(id: item.id, title: item.title, isLocked: locked.contains(item.id))
            categoriesStack.addArrangedSubview(row)
        }
    }

    private func makeCategoryRow(id: Int, title: String, isLocked: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 48).isActive = true
        row.backgroundColor = UIColor(white: 0.97, alpha: 1)
        row.layer.cornerRadius = 10

        let lock = UIImageView(image: UIImage(named: "parentalControlLockIcon") ?? UIImage(systemName: "lock.fill"))
        lock.translatesAutoresizingMaskIntoConstraints = false
        lock.contentMode = .scaleAspectFit
        lock.tintColor = ParentalPalette.accent
        lock.isHidden = !isLocked

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = UIFont(name: "Poppins-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        label.textColor = ParentalPalette.title

        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = isLocked
        toggle.onTintColor = ParentalPalette.accent
        toggle.tag = id
        toggle.addTarget(self, action: #selector(categoryLockToggled(_:)), for: .valueChanged)

        row.addSubview(lock)
        row.addSubview(label)
        row.addSubview(toggle)
        NSLayoutConstraint.activate([
            lock.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 10),
            lock.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            lock.widthAnchor.constraint(equalToConstant: 18),
            lock.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: lock.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),

            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    // MARK: - Actions

    @objc private func setupTapped() {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let pin = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirm = confirmPinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard pin.count >= 4, pin.count <= 6, pin.allSatisfy(\.isNumber) else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINInvalid))
            return
        }
        guard pin == confirm else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINMismatch))
            return
        }
        let limit = Int(limitSlider.value.rounded())
        setLoading(true)
        APIManager.shared.setupParentalControls(msisdn: msisdn, pin: pin, dailyLimitMinutes: limit) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.verifiedSessionPIN = pin
                    self?.refreshStatusThen { self?.setMode(.dashboard) }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    @objc private func verifyTapped() {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let pin = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !pin.isEmpty else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINInvalid))
            return
        }
        setLoading(true)
        APIManager.shared.verifyParentalPIN(msisdn: msisdn, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.parentalPINWrong))
                        return
                    }
                    self?.verifiedSessionPIN = pin
                    self?.refreshStatusThen { self?.setMode(.dashboard) }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    @objc private func updateLimitTapped() {
        promptForPINIfNeeded(title: AppL10n.t(.parentalUpdateLimit)) { [weak self] pin in
            self?.performUpdateLimit(currentPIN: pin)
        }
    }

    @objc private func changePINTapped() {
        setMode(.changePIN)
    }

    @objc private func saveChangePINTapped() {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let current = pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let newPIN = newPinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirm = confirmPinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !current.isEmpty else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINInvalid))
            return
        }
        guard newPIN.count >= 4, newPIN.count <= 6, newPIN.allSatisfy(\.isNumber) else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINInvalid))
            return
        }
        guard newPIN == confirm else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINMismatch))
            return
        }
        let limit = status?.dailyLimitMinutes ?? Int(limitSlider.value.rounded())
        setLoading(true)
        APIManager.shared.updateParentalControls(
            msisdn: msisdn,
            currentPIN: current,
            newPIN: newPIN,
            dailyLimitMinutes: limit
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.verifiedSessionPIN = newPIN
                    self?.presentAlert(AppL10n.t(.successTitle), response.message ?? AppL10n.t(.successTitle)) { [weak self] in
                        self?.setMode(.dashboard)
                    }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    private func performUpdateLimit(currentPIN: String) {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let limit = Int(limitSlider.value.rounded())
        setLoading(true)
        APIManager.shared.updateParentalControls(
            msisdn: msisdn,
            currentPIN: currentPIN,
            newPIN: nil,
            dailyLimitMinutes: limit
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.verifiedSessionPIN = currentPIN
                    self?.presentAlert(AppL10n.t(.successTitle), response.message ?? AppL10n.t(.successTitle))
                    self?.refreshStatusThen {
                        self?.applyStatusToTodayUI()
                        self?.limitSlider.value = Float(self?.status?.dailyLimitMinutes ?? limit)
                        self?.updateLimitLabel()
                        self?.rebuildCategoryRows()
                    }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    /// Uses the PIN from the verify session when available; otherwise asks once.
    private func promptForPINIfNeeded(title: String, onPIN: @escaping (String) -> Void) {
        if let pin = verifiedSessionPIN, !pin.isEmpty {
            onPIN(pin)
            return
        }
        let alert = UIAlertController(
            title: title,
            message: AppL10n.t(.parentalEnterPIN),
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = AppL10n.t(.parentalEnterPIN)
            field.isSecureTextEntry = true
            field.keyboardType = .numberPad
            field.textAlignment = .center
        }
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default) { [weak self] _ in
            let pin = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !pin.isEmpty else {
                self?.presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINInvalid))
                return
            }
            self?.verifiedSessionPIN = pin
            onPIN(pin)
        })
        present(alert, animated: true)
    }

    @objc private func forgotPINTapped() {
        setMode(.resetRequest)
    }

    @objc private func disableTapped() {
        guard UserSession.msisdnDigits != nil else { return }
        let alert = UIAlertController(
            title: AppL10n.t(.parentalDisable),
            message: AppL10n.t(.parentalDisableConfirm),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: AppL10n.t(.parentalDisable), style: .destructive) { [weak self] _ in
            self?.promptForPINIfNeeded(title: AppL10n.t(.parentalDisable)) { pin in
                self?.performDisable(pin: pin)
            }
        })
        present(alert, animated: true)
    }

    private func performDisable(pin: String) {
        guard let msisdn = UserSession.msisdnDigits else { return }
        setLoading(true)
        APIManager.shared.disableParentalControls(msisdn: msisdn, pin: pin) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    ParentalStatusStore.clear()
                    self?.verifiedSessionPIN = nil
                    self?.status = nil
                    self?.presentAlert(AppL10n.t(.successTitle), response.message ?? "") { [weak self] in
                        self?.setMode(.setup)
                    }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    @objc private func categoryLockToggled(_ sender: UISwitch) {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let categoryId = sender.tag
        setLoading(true)
        let completion: (Result<ParentalMessageResponse, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        sender.isOn.toggle()
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.refreshStatusThen {
                        self?.rebuildCategoryRows()
                    }
                case .failure(let error):
                    sender.isOn.toggle()
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
        if sender.isOn {
            APIManager.shared.lockParentalCategory(msisdn: msisdn, categoryId: categoryId, completion: completion)
        } else {
            APIManager.shared.unlockParentalCategory(msisdn: msisdn, categoryId: categoryId, completion: completion)
        }
    }

    @objc private func requestResetOTPTapped() {
        guard let phone = UserSession.msisdnDigits else { return }
        setLoading(true)
        APIManager.shared.requestParentalPINReset(phone: phone) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.setMode(.resetConfirm)
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    @objc private func confirmResetTapped() {
        guard let msisdn = UserSession.msisdnDigits else { return }
        let otp = otpField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pin = newPinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirm = confirmPinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !otp.isEmpty else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalEnterOTP))
            return
        }
        guard pin.count >= 4, pin == confirm else {
            presentAlert(AppL10n.t(.errorTitle), AppL10n.t(.parentalPINMismatch))
            return
        }
        setLoading(true)
        APIManager.shared.confirmParentalPINReset(msisdn: msisdn, otp: otp, newPIN: pin) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        self?.presentAlert(AppL10n.t(.errorTitle), response.message ?? AppL10n.t(.errorTitle))
                        return
                    }
                    self?.verifiedSessionPIN = pin
                    self?.presentAlert(AppL10n.t(.successTitle), response.message ?? "") { [weak self] in
                        self?.refreshStatusThen { self?.setMode(.dashboard) }
                    }
                case .failure(let error):
                    self?.presentAlert(AppL10n.t(.errorTitle), error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Helpers

    private func refreshStatusThen(_ done: @escaping () -> Void) {
        ParentalStatusStore.refreshInBackground { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let status) = result {
                    self?.status = status
                } else {
                    self?.status = ParentalStatusStore.current
                }
                done()
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        view.isUserInteractionEnabled = !loading
        if loading { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    private func presentAlert(_ title: String, _ message: String, onOK: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default) { _ in onOK?() })
        present(alert, animated: true)
    }

    @objc private func backTapped() {
        switch mode {
        case .changePIN:
            setMode(.dashboard)
        case .resetRequest, .resetConfirm:
            if status?.isEnabled == true {
                setMode(verifiedSessionPIN == nil ? .verify : .dashboard)
            } else {
                setMode(.setup)
            }
        default:
            if let nav = navigationController, nav.viewControllers.first != self {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }

    @objc private func endEditingTap() {
        view.endEditing(true)
    }
}

// MARK: - Unlock locked category (Home)

enum ParentalPINGate {

    /// Asks for PIN when a locked category is opened. Calls `onUnlocked` only after successful verify.
    static func unlockCategoryIfNeeded(
        categoryId: Int,
        from viewController: UIViewController,
        onUnlocked: @escaping () -> Void
    ) {
        guard ParentalStatusStore.isCategoryLocked(categoryId) else {
            onUnlocked()
            return
        }
        guard let msisdn = UserSession.msisdnDigits else {
            let alert = UIAlertController(
                title: AppL10n.t(.errorTitle),
                message: AppL10n.t(.parentalNeedPhone),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
            viewController.present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: AppL10n.t(.parentalCategoryLockedTitle),
            message: AppL10n.t(.parentalCategoryLockedMessage),
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.placeholder = AppL10n.t(.parentalEnterPIN)
            field.isSecureTextEntry = true
            field.keyboardType = .numberPad
            field.textAlignment = .center
        }
        alert.addAction(UIAlertAction(title: AppL10n.t(.cancel), style: .cancel))
        alert.addAction(UIAlertAction(title: AppL10n.t(.parentalUnlock), style: .default) { _ in
            let pin = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !pin.isEmpty else { return }
            APIManager.shared.verifyParentalPIN(msisdn: msisdn, pin: pin) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response) where response.isSuccess:
                        onUnlocked()
                    case .success(let response):
                        let fail = UIAlertController(
                            title: AppL10n.t(.errorTitle),
                            message: response.message ?? AppL10n.t(.parentalPINWrong),
                            preferredStyle: .alert
                        )
                        fail.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
                        viewController.present(fail, animated: true)
                    case .failure(let error):
                        let fail = UIAlertController(
                            title: AppL10n.t(.errorTitle),
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        fail.addAction(UIAlertAction(title: AppL10n.t(.ok), style: .default))
                        viewController.present(fail, animated: true)
                    }
                }
            }
        })
        viewController.present(alert, animated: true)
    }
}
