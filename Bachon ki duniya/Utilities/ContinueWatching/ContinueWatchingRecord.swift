import Foundation

/// Local continue-watching row (aligned with Android `VideoDatabase` + `video_url` for resume playback).
struct ContinueWatchingRecord: Equatable {
    let id: Int64
    let videoId: Int
    var title: String?
    var durationMs: Int64
    var imageURL: String?
    var lastPositionMs: Int64
    var durationPlayedMs: Int64
    var systemTimeMs: Int64
    var updatedOnline: Int
    var videoURL: String

    var progress: Float {
        guard durationMs > 0 else { return 0 }
        let watched = max(lastPositionMs, durationPlayedMs)
        return min(1, Float(watched) / Float(durationMs))
    }

    var isNearlyComplete: Bool {
        progress >= 0.95
    }
}

struct VideoPlaybackContext {
    let videoId: Int
    let title: String
    let thumbnailURL: String?
    let durationMs: Int64
    let videoURL: String
    let startPositionMs: Int64

    init(
        videoId: Int,
        title: String,
        thumbnailURL: String?,
        durationMs: Int64,
        videoURL: String,
        startPositionMs: Int64 = 0
    ) {
        self.videoId = videoId
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.durationMs = durationMs
        self.videoURL = videoURL
        self.startPositionMs = startPositionMs
    }

    static func from(episode: StoryEpisode) -> VideoPlaybackContext? {
        guard let url = episode.videoURL, !url.isEmpty else { return nil }
        let durationMs = Int64(episode.durationSecs ?? 0) * 1000
        return VideoPlaybackContext(
            videoId: episode.id,
            title: episode.title,
            thumbnailURL: episode.thumbnailURL,
            durationMs: durationMs,
            videoURL: url
        )
    }

    static func from(episode: LatestEpisode, title: String) -> VideoPlaybackContext? {
        guard let url = episode.videoURL, !url.isEmpty else { return nil }
        let durationMs = Int64(episode.durationSecs ?? 0) * 1000
        return VideoPlaybackContext(
            videoId: episode.id,
            title: title,
            thumbnailURL: episode.thumbnailURL,
            durationMs: durationMs,
            videoURL: url
        )
    }

    static func from(record: ContinueWatchingRecord) -> VideoPlaybackContext? {
        guard !record.videoURL.isEmpty else { return nil }
        return VideoPlaybackContext(
            videoId: record.videoId,
            title: record.title ?? "",
            thumbnailURL: record.imageURL,
            durationMs: record.durationMs,
            videoURL: record.videoURL,
            startPositionMs: record.lastPositionMs
        )
    }
}

extension Notification.Name {
    static let continueWatchingDidChange = Notification.Name("ContinueWatchingDidChange")
}
