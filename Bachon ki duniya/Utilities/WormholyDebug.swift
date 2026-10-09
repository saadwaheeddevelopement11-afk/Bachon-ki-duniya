//
//  WormholyDebug.swift
//  Bachon ki duniya
//
//  Debug-only helpers so Wormholy opens reliably on device.
//

import UIKit

#if DEBUG
import Wormholy
#endif

enum WormholyDebug {
    static func activate() {
        #if DEBUG
        Wormholy.shakeEnabled = true
        installTwoFingerDoubleTapFallback()
        print("[Wormholy] enabled — shake device, or two-finger double-tap, to open network log")
        #endif
    }

    static func present() {
        #if DEBUG
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "wormholy_fire"), object: nil)
        #endif
    }

    #if DEBUG
    private static func installTwoFingerDoubleTapFallback() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else { return }

            let existing = window.gestureRecognizers?.contains { $0.name == "wormholy_two_finger" } ?? false
            guard !existing else { return }

            let tap = UITapGestureRecognizer(target: WormholyTapTarget.shared, action: #selector(WormholyTapTarget.fire))
            tap.numberOfTapsRequired = 2
            tap.numberOfTouchesRequired = 2
            tap.name = "wormholy_two_finger"
            tap.cancelsTouchesInView = false
            window.addGestureRecognizer(tap)
        }
    }

    private final class WormholyTapTarget: NSObject {
        static let shared = WormholyTapTarget()
        @objc func fire() {
            WormholyDebug.present()
        }
    }
    #endif
}
