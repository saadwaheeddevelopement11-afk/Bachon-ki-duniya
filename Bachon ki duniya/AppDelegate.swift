//
//  AppDelegate.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 10/03/2026.
//

import UIKit
import FirebaseCore
import FirebaseCrashlytics

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        AppAnalytics.configureUserProperties()
        if let msisdn = UserSession.msisdnDigits {
            Crashlytics.crashlytics().setUserID(msisdn)
        }

        KeyboardDismiss.installGlobally()
        AppScreenTimeTracker.shared.startSessionIfNeeded()
        UserProfileSync.refreshInBackground()
        ParentalStatusStore.refreshInBackground()

        PushNotificationManager.shared.configure(application: application)
        WormholyDebug.activate()

        AppAnalytics.log("app_open")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        AppScreenTimeTracker.shared.endSessionIfNeeded()
    }

    // MARK: - Remote notifications (APNs → FCM)

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationManager.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushNotificationManager.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppOrientation.shared.supportedMask
    }
}
