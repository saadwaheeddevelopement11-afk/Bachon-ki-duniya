import Foundation

enum ContinueWatchingStore {

    private static let minimumWatchedMs: Int64 = 3_000

    static func saveProgress(context: VideoPlaybackContext, currentPositionMs: Int64, durationMs: Int64) {
        let played = max(currentPositionMs, 0)
        guard played >= minimumWatchedMs else { return }

        let totalDuration = max(durationMs, context.durationMs, played)
        ContinueWatchingDatabase.shared.upsert(
            videoId: context.videoId,
            title: context.title,
            durationMs: totalDuration,
            imageURL: context.thumbnailURL,
            lastPositionMs: played,
            durationPlayedMs: played,
            videoURL: context.videoURL
        )
        notifyChange()
    }

    static func removeIfCompleted(videoId: Int, currentPositionMs: Int64, durationMs: Int64) {
        guard durationMs > 0 else { return }
        let ratio = Double(currentPositionMs) / Double(durationMs)
        if ratio >= 0.95 {
            ContinueWatchingDatabase.shared.delete(videoId: videoId)
            notifyChange()
        }
    }

    static func fetchForHome(limit: Int = 12, completion: @escaping ([ContinueWatchingRecord]) -> Void) {
        ContinueWatchingDatabase.shared.fetchRecent(limit: limit) { records in
            let visible = records.filter { !$0.isNearlyComplete && $0.progress > 0 }
            completion(visible)
        }
    }

    private static func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .continueWatchingDidChange, object: nil)
        }
    }
}
