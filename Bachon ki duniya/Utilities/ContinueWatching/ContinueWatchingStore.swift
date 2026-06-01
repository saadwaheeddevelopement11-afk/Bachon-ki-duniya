import Foundation

enum ContinueWatchingStore {

    /// Mirrors Android `saveVideo`. All time arguments are **milliseconds**; skips when duration/watchTime < 1 ms.
    static func saveVideo(
        context: VideoPlaybackContext,
        playerDurationMs: Int64,
        currentPositionMs: Int64,
        watchTimeMs: Int64,
        postToServer: Bool
    ) {
        guard playerDurationMs >= 1, watchTimeMs >= 1 else { return }

        let isFinished = currentPositionMs >= playerDurationMs - 1000
        var positionMs = currentPositionMs
        if isFinished {
            positionMs = playerDurationMs
        }

        ContinueWatchingDatabase.shared.upsert(
            videoId: context.videoId,
            title: context.title,
            durationMs: playerDurationMs,
            imageURL: context.thumbnailURL,
            lastPositionMs: positionMs,
            durationPlayedMs: watchTimeMs,
            videoURL: context.videoURL
        )

        if postToServer {
            WatchTracker.track(
                episodeId: context.videoId,
                durationMs: playerDurationMs,
                positionMs: positionMs,
                watchTimeMs: watchTimeMs
            )
            notifyChange()
        }
    }

    static func fetchForHome(limit: Int = 12, completion: @escaping ([ContinueWatchingRecord]) -> Void) {
        ContinueWatchingDatabase.shared.fetchRecent(limit: limit) { records in
            let visible = records.filter { record in
                guard record.durationMs > 0 else { return false }
                let position = max(record.lastPositionMs, record.durationPlayedMs)
                return position < record.durationMs - 1000
            }
            completion(visible)
        }
    }

    private static func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .continueWatchingDidChange, object: nil)
        }
    }
}
