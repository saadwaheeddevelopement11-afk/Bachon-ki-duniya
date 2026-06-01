import Foundation

/// POST /watch/track — sync watch progress when the user closes the player (Android parity).
/// Payload times are **milliseconds** (`duration`, `position`, `watch_time`).
enum WatchTracker {

    private static let endpoint = "https://kidskahani.ideationtec.live/watch/track"

    struct Payload: Encodable {
        let msisdn: Int64
        let episode_id: Int
        /// Total media length in **milliseconds**.
        let duration: Int64
        /// Playback position in **milliseconds**.
        let position: Int64
        /// Accumulated watch time in **milliseconds**.
        let watch_time: Int64
    }

    static func track(
        episodeId: Int,
        durationMs: Int64,
        positionMs: Int64,
        watchTimeMs: Int64
    ) {
        guard durationMs >= 1, watchTimeMs >= 1 else { return }
        guard let msisdn = UserSession.msisdn else {
            print("WatchTracker: msisdn not set — log out and sign in with your phone, or save it from the Home prompt.")
            return
        }

        let body = Payload(
            msisdn: msisdn,
            episode_id: episodeId,
            duration: durationMs,
            position: positionMs,
            watch_time: watchTimeMs
        )

        guard let url = URL(string: endpoint),
              let data = try? JSONEncoder().encode(body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = data

        #if DEBUG
        print("WatchTracker POST (ms): episode=\(episodeId) duration=\(durationMs) position=\(positionMs) watch_time=\(watchTimeMs)")
        #endif

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error {
                print("WatchTracker failed: \(error.localizedDescription)")
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                print("WatchTracker HTTP \(http.statusCode)")
            }
        }.resume()
    }
}
