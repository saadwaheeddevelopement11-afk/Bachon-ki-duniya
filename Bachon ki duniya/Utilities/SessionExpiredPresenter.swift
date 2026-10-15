import UIKit

/// Shows the Session Expired popup when `/profile` reports `token_validation == false`.
/// Clears the OTP `session_token` immediately so the app treats the user as logged out
/// even if they dismiss nothing / never tap the button.
enum SessionExpiredPresenter {

    private static weak var activePopup: SessionExpiredPopupView?
    private static var isHandling = false

    static func presentIfNeeded() {
        DispatchQueue.main.async {
            guard !isHandling, activePopup == nil else { return }

            let stillLooksLoggedIn = UserDefaults.standard.bool(forKey: AppDefaultsKeys.isLoggedIn)
                || UserSession.sessionToken != nil
            guard stillLooksLoggedIn else { return }
            guard let host = topHostView() else { return }

            isHandling = true

            // Drop session immediately — app knows nobody is authenticated anymore.
            UserSession.clearSessionToken()
            UserDefaults.standard.set(false, forKey: AppDefaultsKeys.isLoggedIn)
            isLoggedIn = false

            let popup = SessionExpiredPopupView()
            popup.onLoginAgain = {
                activePopup?.dismiss(animated: true) {
                    activePopup = nil
                    isHandling = false
                    finishLogoutAndGoToLogin()
                }
            }
            activePopup = popup
            popup.present(in: host)
        }
    }

    private static func finishLogoutAndGoToLogin() {
        AppAnalytics.logLogout()
        AppAnalytics.clearUser()
        UserSession.clearMsisdn()
        UserProfileStore.clear()
        BookmarkStore.clear()
        AppRouter.setRoot(.login, animated: true)
    }

    private static func topHostView() -> UIView? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
            ?? scenes.first?.windows.first
        return window
    }
}
