import UIKit

/// Ensures `UserSession` has a phone number for `/watch/track` (logged-in users who never saved msisdn).
enum MsisdnCapturePresenter {

    private static weak var presentedFrom: UIViewController?

    static func presentIfNeeded(from viewController: UIViewController) {
        guard UserSession.msisdn == nil else { return }
        guard presentedFrom !== viewController else { return }
        guard viewController.presentedViewController == nil else { return }

        presentedFrom = viewController

        let alert = UIAlertController(
            title: "Phone number required",
            message: "Enter your mobile number so we can save your watch progress.",
            preferredStyle: .alert
        )
        alert.addTextField { field in
            field.keyboardType = .phonePad
            field.placeholder = "923001234567"
            field.text = UserSession.msisdnDigits
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            presentedFrom = nil
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            presentedFrom = nil
            let raw = alert.textFields?.first?.text ?? ""
            let digits = UserSession.normalizePhoneDigits(raw)
            guard UserSession.isValidPakistanMSISDN(digits) else {
                showInvalidAlert(on: viewController)
                return
            }
            UserSession.saveMsisdn(digits: digits)
            UserProfileSync.refreshInBackground()
            #if DEBUG
            print("UserSession: msisdn saved (\(digits))")
            #endif
        })
        viewController.present(alert, animated: true)
    }

    private static func showInvalidAlert(on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Invalid phone number",
            message: "Please enter a valid number (10–15 digits, e.g. 923001234567).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            presentIfNeeded(from: viewController)
        })
        viewController.present(alert, animated: true)
    }
}
 