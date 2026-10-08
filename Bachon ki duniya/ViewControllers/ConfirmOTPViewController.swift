//
//  ConfirmOTPViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 16/03/2026.
//

import UIKit
import FirebaseCrashlytics

class ConfirmOTPViewController: UIViewController {

    /// Set by `LoginViewController` when presenting this screen.
    var pendingMsisdnDigits: String?
    var expiresInText: String?

    private let otpBoxes = OTPBoxesView()
    private var isVerifying = false
    private weak var subtitleLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        wireUI()
        setupBackButton()
        updateSubtitle()
    }
    
    @IBAction func continueBtn(_ sender: UIButton) {
        verifyAndContinue()
    }
}

private extension ConfirmOTPViewController {
    
    func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(named: "backIcon")?.withRenderingMode(.alwaysOriginal), for: .normal)
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        view.bringSubviewToFront(backButton)
    }

    @objc func backTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    func wireUI() {
        // Dismiss keyboard on tap outside boxes.
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // Subtitle under "Confirm OTP" (mentions phone).
        if let subtitle = view.allSubviews(of: UILabel.self).first(where: {
            ($0.text ?? "").localizedCaseInsensitiveContains("4-digit")
                || ($0.text ?? "").contains("+92")
        }) {
            subtitleLabel = subtitle
        }

        // Empty 80pt placeholder above Continue — host OTP boxes here.
        if let otpContainer = view.allSubviews(of: UIView.self).first(where: { candidate in
            candidate.subviews.isEmpty
                && candidate.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 80) < 0.5 })
        }) {
            installOTPBoxes(in: otpContainer)
        } else {
            // Fallback: place above the continue button container.
            installOTPBoxes(in: view)
        }
        
        // The storyboard uses an image as a button (SignInBtn). Make it tappable.
        if let continueImageView = view.allSubviews(of: UIImageView.self).first(where: { imageView in
            let hasHeight60 = imageView.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 60) < 0.5 })
            let parentHasHeight80 = imageView.superview?.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 80) < 0.5 }) == true
            return hasHeight60 && parentHasHeight80
        }) {
            continueImageView.isUserInteractionEnabled = true
            continueImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(continueTapped)))
        }

        otpBoxes.onCodeCompleted = { [weak self] _ in
            self?.verifyAndContinue()
        }
    }

    func installOTPBoxes(in container: UIView) {
        otpBoxes.translatesAutoresizingMaskIntoConstraints = false
        otpBoxes.digitCount = 4
        container.addSubview(otpBoxes)
        NSLayoutConstraint.activate([
            otpBoxes.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            otpBoxes.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            otpBoxes.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            otpBoxes.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    func updateSubtitle() {
        guard let phone = pendingMsisdnDigits, !phone.isEmpty else { return }
        let display = UserSession.formattedPhone(phone)
        var message = "Enter the 4-digit code sent to\n\(display)"
        if let expiresInText, !expiresInText.isEmpty {
            message += "\nExpires in \(expiresInText)"
        }
        subtitleLabel?.text = message
        subtitleLabel?.numberOfLines = 3
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    @objc func continueTapped() {
        verifyAndContinue()
    }
    
    func verifyAndContinue() {
        view.endEditing(true)
        guard !isVerifying else { return }

        guard let phone = pendingMsisdnDigits.flatMap({ raw -> String? in
            let normalized = UserSession.normalizePhoneDigits(raw)
            return UserSession.isValidPakistanMSISDN(normalized) ? normalized : nil
        }) else {
            presentAlert(title: "OTP", message: "Phone number missing. Please go back and try again.")
            return
        }

        let otp = otpBoxes.code
        guard otp.count == 4 else {
            presentAlert(title: "OTP", message: "Please enter the 4-digit OTP.")
            otpBoxes.focusField()
            return
        }

        isVerifying = true
        setVerifying(true)

        APIManager.shared.verifyOTP(phone: phone, otp: otp) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isVerifying = false
                self.setVerifying(false)

                switch result {
                case .success(let response):
                    let ok = response.status.lowercased() == "success" || response.code == "000"
                    guard ok else {
                        self.presentAlert(
                            title: "OTP",
                            message: response.message ?? "Invalid or expired OTP"
                        )
                        self.otpBoxes.clear()
                        self.otpBoxes.focusField()
                        return
                    }
                    self.completeLogin(phone: phone)
                case .failure(let error):
                    self.presentAlert(title: "OTP", message: error.localizedDescription)
                }
            }
        }
    }

    func completeLogin(phone: String) {
        UserSession.saveMsisdn(digits: phone)
        UserDefaults.standard.set(true, forKey: AppDefaultsKeys.isLoggedIn)
        isLoggedIn = true
        AppAnalytics.configureUserProperties(msisdn: phone)
        AppAnalytics.logLogin(method: "otp")
        Crashlytics.crashlytics().setUserID(phone)
        UserProfileSync.refreshInBackground()
        AppRouter.setRoot(.main)
    }

    func setVerifying(_ loading: Bool) {
        view.isUserInteractionEnabled = !loading
        if loading {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.tag = 88002
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            view.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        } else {
            view.viewWithTag(88002)?.removeFromSuperview()
        }
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private extension UIView {
    func allSubviews<T: UIView>(of type: T.Type) -> [T] {
        var result: [T] = []
        for sub in subviews {
            if let t = sub as? T { result.append(t) }
            result.append(contentsOf: sub.allSubviews(of: type))
        }
        return result
    }
}
