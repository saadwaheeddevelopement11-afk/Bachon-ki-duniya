//
//  SceneDelegate.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 10/03/2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Sync legacy global flag (used elsewhere in the project)
        isLoggedIn = UserDefaults.standard.bool(forKey: AppDefaultsKeys.isLoggedIn)
        
        let window = UIWindow(windowScene: windowScene)
        // App chrome/assets are light-mode designed; dark mode makes many labels unreadable.
        window.overrideUserInterfaceStyle = .light
        let route = AppRouter.currentRoute()
        let root = AppRouter.makeRootViewController(for: route)
        AppRouter.setRootViewController(window: window, root: root, animated: false)
        self.window = window
        UserProfileSync.refreshInBackground()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        AppScreenTimeTracker.shared.endSessionIfNeeded()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        AppScreenTimeTracker.shared.startSessionIfNeeded()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Keep the session open through brief interruptions (e.g. control center).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppScreenTimeTracker.shared.startSessionIfNeeded()
        UserProfileSync.refreshInBackground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppScreenTimeTracker.shared.endSessionIfNeeded()
    }
}
