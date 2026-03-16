//
//  ConfirmOTPViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 16/03/2026.
//

import UIKit

class ConfirmOTPViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        wireUI()
    }
    
    @IBAction func continueBtn(_ sender: UIButton) {
        completeLogin()
    }
}

private extension ConfirmOTPViewController {
    
    func wireUI() {
        // Dismiss keyboard on tap.
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // The storyboard uses an image as a button (SignInBtn). Make it tappable.
        if let continueImageView = view.allSubviews(of: UIImageView.self).first(where: { imageView in
            let hasHeight60 = imageView.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 60) < 0.5 })
            let parentHasHeight80 = imageView.superview?.constraints.contains(where: { $0.firstAttribute == .height && abs($0.constant - 80) < 0.5 }) == true
            return hasHeight60 && parentHasHeight80
        }) {
            continueImageView.isUserInteractionEnabled = true
            continueImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(continueTapped)))
        }
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    @objc func continueTapped() {
        completeLogin()
    }
    
    func completeLogin() {
        // In a real app you'd verify the OTP. For now, treat "Continue" as success.
        UserDefaults.standard.set(true, forKey: AppDefaultsKeys.isLoggedIn)
        isLoggedIn = true
        AppRouter.setRoot(.main)
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
