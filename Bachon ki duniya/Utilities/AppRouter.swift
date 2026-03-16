import UIKit

enum AppRoute {
    case onboarding
    case login
    case main
}

enum AppDefaultsKeys {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let isLoggedIn = "isLoggedIn"
}

final class AppRouter {
    
    static func currentRoute() -> AppRoute {
        let defaults = UserDefaults.standard
        let hasSeen = defaults.bool(forKey: AppDefaultsKeys.hasSeenOnboarding)
        let loggedIn = defaults.bool(forKey: AppDefaultsKeys.isLoggedIn)
        
        if !hasSeen { return .onboarding }
        return loggedIn ? .main : .login
    }
    
    static func makeRootViewController(for route: AppRoute) -> UIViewController {
        switch route {
        case .onboarding:
            let sb = UIStoryboard(name: "OnboardingVC", bundle: nil)
            return sb.instantiateInitialViewController() ?? UIViewController()
            
        case .login:
            let sb = UIStoryboard(name: "Login", bundle: nil)
            return sb.instantiateInitialViewController() ?? UIViewController()
            
        case .main:
            let sb = UIStoryboard(name: "Main", bundle: nil)
            return sb.instantiateInitialViewController() ?? UIViewController()
        }
    }
    
    static func setRoot(_ route: AppRoute, animated: Bool = true) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }
        
        let root = makeRootViewController(for: route)
        setRootViewController(window: window, root: root, animated: animated)
    }
    
    static func setRootViewController(window: UIWindow, root: UIViewController, animated: Bool) {
        if animated {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                window.rootViewController = root
            }
        } else {
            window.rootViewController = root
        }
        window.makeKeyAndVisible()
    }
}

