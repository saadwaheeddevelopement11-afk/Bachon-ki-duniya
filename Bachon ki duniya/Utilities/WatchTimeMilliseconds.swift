import AVFoundation
import CoreMedia
import Foundation

/// All watch-tracking values (`duration`, `position`, `watch_time`) use **milliseconds**, matching Android `ExoPlayer.duration` / `currentPosition`.
enum WatchTimeMilliseconds {

    /// API `duration_secs` and similar fields are in **seconds** → convert to ms.
    static func fromAPISeconds(_ seconds: Int?) -> Int64 {
        guard let seconds, seconds > 0 else { return 0 }
        return Int64(seconds) * 1000
    }

    /// `AVPlayer` / `CMTime` report time in **seconds** → convert to ms.
    static func fromPlayerSeconds(_ seconds: Double) -> Int64 {
        guard seconds.isFinite, seconds >= 0 else { return 0 }
        return Int64((seconds * 1000).rounded())
    }

    static func fromCMTime(_ time: CMTime) -> Int64 {
        guard time.isValid, !time.isIndefinite else { return 0 }
        let seconds = CMTimeGetSeconds(time)
        return fromPlayerSeconds(seconds)
    }
}
