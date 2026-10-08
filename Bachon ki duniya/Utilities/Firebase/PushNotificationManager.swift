//
//  PushNotificationManager.swift
//  Bachon ki duniya
//

import UIKit
import UserNotifications
import FirebaseMessaging
import FirebaseCrashlytics

final class PushNotificationManager: NSObject {
    static let shared = PushNotificationManager()

    private(set) var fcmToken: String?

    private override init() {
        super.init()
    }

    func configure(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error {
                Crashlytics.crashlytics().record(error: error)
            }
            DispatchQueue.main.async {
                AppAnalytics.log("push_permission", parameters: ["granted": granted ? "yes" : "no"])
                if granted {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    /// Show banner while app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        AppAnalytics.log("notification_open", parameters: [
            "title": response.notification.request.content.title
        ])
        _ = userInfo
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension PushNotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        #if DEBUG
        if let fcmToken {
            print("[FCM] token: \(fcmToken)")
        }
        #endif
        AppAnalytics.log("fcm_token_refresh", parameters: [
            "has_token": fcmToken == nil ? "no" : "yes"
        ])
        // If you later need to send the token to your backend, do it here:
        // APIManager.shared.registerFCMToken(fcmToken)
    }
}
