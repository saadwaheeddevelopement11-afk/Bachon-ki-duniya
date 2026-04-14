//
//  AppOrientation.swift
//  Bachon ki duniya
//

import UIKit

/// Locks the app to portrait normally, but allows landscape while fullscreen video is active.
/// Pair with `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`.
final class AppOrientation {
    static let shared = AppOrientation()

    /// Set to `true` before presenting `AVPlayerViewController` fullscreen; `false` when dismissed.
    var isVideoFullscreenActive = false {
        didSet {
            if oldValue != isVideoFullscreenActive {
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }

    var supportedMask: UIInterfaceOrientationMask {
        isVideoFullscreenActive ? .landscape : .portrait
    }

    private init() {}
}
