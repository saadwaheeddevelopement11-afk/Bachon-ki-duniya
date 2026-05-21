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
    private static let loadingOverlayTag = 919191
    private static let progressSaveIntervalSeconds = 2.0

    @MainActor
    static func play(
        urlString: String,
        context: VideoPlaybackContext? = nil,
        from presenter: UIViewController
    ) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = resolvedURL(from: trimmed) else {
            return
        }
        showLoader(on: presenter.view)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session: \(error.localizedDescription)")
            hideLoader(from: presenter.view)
        }

        let asset = AVURLAsset(url: url)
        Task { @MainActor in
            do {
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else {
                    hideLoader(from: presenter.view)
                    return
                }

                let durationSeconds = try await asset.load(.duration).seconds
                let durationMs = Int64(durationSeconds * 1000)
                var resolvedContext = context
                if var ctx = resolvedContext, ctx.durationMs <= 0, durationMs > 0 {
                    resolvedContext = VideoPlaybackContext(
                        videoId: ctx.videoId,
                        title: ctx.title,
                        thumbnailURL: ctx.thumbnailURL,
                        durationMs: durationMs,
                        videoURL: ctx.videoURL,
                        startPositionMs: ctx.startPositionMs
                    )
                }

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

                let playbackContext = resolvedContext
                var timeObserver: Any?
                var observedDurationMs = playbackContext?.durationMs ?? durationMs

                func saveProgress(forceFinal: Bool = false) {
                    guard let playbackContext else { return }
                    let currentSeconds = player.currentTime().seconds
                    guard currentSeconds.isFinite, currentSeconds >= 0 else { return }
                    let currentMs = Int64(currentSeconds * 1000)
                    let totalMs = max(observedDurationMs, playbackContext.durationMs, currentMs)
                    observedDurationMs = totalMs
                    ContinueWatchingStore.saveProgress(
                        context: VideoPlaybackContext(
                            videoId: playbackContext.videoId,
                            title: playbackContext.title,
                            thumbnailURL: playbackContext.thumbnailURL,
                            durationMs: totalMs,
                            videoURL: playbackContext.videoURL
                        ),
                        currentPositionMs: currentMs,
                        durationMs: totalMs
                    )
                    if forceFinal {
                        ContinueWatchingStore.removeIfCompleted(
                            videoId: playbackContext.videoId,
                            currentPositionMs: currentMs,
                            durationMs: totalMs
                        )
                    }
                }

                playerVC.onEndPlaybackOrDismiss = {
                    if let token = timeObserver {
                        player.removeTimeObserver(token)
                        timeObserver = nil
                    }
                    saveProgress(forceFinal: true)
                    AppOrientation.shared.isVideoFullscreenActive = false
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIViewController.attemptRotationToDeviceOrientation()
                    do {
                        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                    } catch {
                        print("Audio session deactivate: \(error.localizedDescription)")
                    }
                }

                if let startMs = playbackContext?.startPositionMs, startMs > 0 {
                    let startSeconds = min(Double(startMs) / 1000, max(0, durationSeconds - 1))
                    let seekTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        player.seek(to: seekTime) { _ in
                            continuation.resume()
                        }
                    }
                }

                if playbackContext != nil {
                    let interval = CMTime(seconds: progressSaveIntervalSeconds, preferredTimescale: 600)
                    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { _ in
                        saveProgress()
                    }
                }

                AppOrientation.shared.isVideoFullscreenActive = true
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    presenter.present(playerVC, animated: true) {
                        hideLoader(from: presenter.view)
                        player.play()
                    }
                }
            } catch {
                print("Video load error: \(error.localizedDescription)")
                hideLoader(from: presenter.view)
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

    private static func showLoader(on view: UIView) {
        guard view.viewWithTag(loadingOverlayTag) == nil else { return }

        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.22)
        overlay.tag = loadingOverlayTag

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        overlay.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        view.addSubview(overlay)
    }

    private static func hideLoader(from view: UIView) {
        view.viewWithTag(loadingOverlayTag)?.removeFromSuperview()
    }
}

// MARK: - Player VC

final class LandscapeFriendlyPlayerViewController: AVPlayerViewController {

    var onEndPlaybackOrDismiss: (() -> Void)?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .landscape
    }

    override var shouldAutorotate: Bool {
        true
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .landscapeRight
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            onEndPlaybackOrDismiss?()
            onEndPlaybackOrDismiss = nil
        }
    }
}
