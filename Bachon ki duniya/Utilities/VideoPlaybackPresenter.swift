//
//  VideoPlaybackPresenter.swift
//  Bachon ki duniya
//

import AVFoundation
import AVKit
import UIKit

/// Fullscreen video with system `AVPlayerViewController` — portrait app unlocks landscape only during playback (Deikho-style).
enum VideoPlaybackPresenter {
    private static let mediaBaseURL = "https://whatsin.deikhlo.com/"

    @MainActor
    static func play(urlString: String, from presenter: UIViewController) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = resolvedURL(from: trimmed) else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session: \(error.localizedDescription)")
        }

        let asset = AVURLAsset(url: url)
        Task { @MainActor in
            do {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else { return }

                let item = AVPlayerItem(asset: asset)
                let player = AVPlayer(playerItem: item)
                let playerVC = LandscapeFriendlyPlayerViewController()
                playerVC.player = player
                playerVC.modalPresentationStyle = .fullScreen
                playerVC.showsPlaybackControls = true
                playerVC.allowsPictureInPicturePlayback = true
                if #available(iOS 16.0, *) {
                    playerVC.allowsVideoFrameAnalysis = true
                }

                playerVC.onEndPlaybackOrDismiss = {
                    AppOrientation.shared.isVideoFullscreenActive = false
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                    do {
                        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                    } catch {
                        print("Audio session deactivate: \(error.localizedDescription)")
                    }
                }

                AppOrientation.shared.isVideoFullscreenActive = true
                presenter.present(playerVC, animated: true) {
                    player.play()
                }
            } catch {
                print("Video load error: \(error.localizedDescription)")
            }
        }
    }
    
    private static func resolvedURL(from rawPath: String) -> URL? {
        if rawPath.hasPrefix("http://") || rawPath.hasPrefix("https://") {
            return URL(string: rawPath)
        }
        
        let normalizedPath = rawPath.hasPrefix("/") ? String(rawPath.dropFirst()) : rawPath
        return URL(string: mediaBaseURL + normalizedPath)
    }
}

// MARK: - Player VC

final class LandscapeFriendlyPlayerViewController: AVPlayerViewController {

    var onEndPlaybackOrDismiss: (() -> Void)?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            onEndPlaybackOrDismiss?()
            onEndPlaybackOrDismiss = nil
        }
    }
}
