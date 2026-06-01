//
//  LoginViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 16/03/2026.
//

import UIKit

class LoginViewController: UIViewController {

    // Note: storyboard currently has no outlet connections, so we locate views at runtime.
    private weak var phoneTextField: UITextField?

    /// Digits entered on the login screen (for OTP + watch tracking).
    var currentPhoneDigits: String? {
        let digits = (phoneTextField?.text ?? "").filter(\.isNumber)
        guard (10...15).contains(digits.count) else { return nil }
        return UserSession.normalizePhoneDigits(digits)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wireUI()
    }
    
    @IBAction func getOTPBtn(_ sender: UIButton) {
        handleGetOTP()
    }
}

private extension LoginViewController {
    
    func wireUI() {
        // Dismiss keyboard on tap.
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Find the phone text field (placeholder in storyboard: "Enter your phone number")
        let allTextFields = view.allSubviews(of: UITextField.self)
        if let tf = allTextFields.first {
            phoneTextField = tf
            tf.keyboardType = .phonePad
            tf.returnKeyType = .done
            tf.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        }
        
        // Make the "Get OTP" area tappable (the storyboard uses an image as a button).
        // We locate the image view that has a height constraint of 60 inside a container view of height 80.
        if let getOtpImageView = view.allSubviews(of: UIImageView.self).first(where: { imageView in
            let hasHeight60 = imageView.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 60) < 0.5 })
            let parentHasHeight80 = imageView.superview?.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 80) < 0.5 }) == true
            return hasHeight60 && parentHasHeight80
        }) {
            getOtpImageView.isUserInteractionEnabled = true
            getOtpImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(getOtpTapped)))
        }
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    @objc func getOtpTapped() {
        handleGetOTP()
    }
    
    @objc func textFieldEditingChanged(_ sender: UITextField) {
        // Keep digits only and limit to 15 digits (E.164 max).
        let digits = (sender.text ?? "").filter(\.isNumber)
        sender.text = String(digits.prefix(15))
    }
    
    func handleGetOTP() {
        view.endEditing(true)
        
        let raw = phoneTextField?.text ?? ""
        let digits = raw.filter(\.isNumber)
        
        // Basic validation: 10-15 digits (covers local and E.164 without '+').
        guard (10...15).contains(digits.count) else {
            presentAlert(title: "Invalid phone number", message: "Please enter a valid phone number.")
            return
        }
        
        let normalized = UserSession.normalizePhoneDigits(digits)
        UserSession.saveMsisdn(digits: normalized)

        // Navigate to Confirm OTP screen
        let sb = UIStoryboard(name: "Login", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "ConfirmOTPViewController") as? ConfirmOTPViewController else {
            return
        }
        vc.pendingMsisdnDigits = normalized
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
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
