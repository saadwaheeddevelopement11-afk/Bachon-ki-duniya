import Foundation

struct AppScreenTimeSession: Codable, Equatable {
    let id: String
    let startedAt: Date
    let endedAt: Date

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }
}

/// Aggregated app-open time for one calendar day.
struct AppScreenTimeDaySummary: Equatable {
    let dayStart: Date
    let duration: TimeInterval
    let sessionCount: Int

    var formattedDuration: String {
        AppScreenTimeTracker.formatDuration(duration)
    }
}

extension Notification.Name {
    static let appScreenTimeDidChange = Notification.Name("AppScreenTimeDidChange")
}

/// Tracks how long the app is in the foreground (not video watch time).
final class AppScreenTimeTracker {

    static let shared = AppScreenTimeTracker()

    private let storageKey = "AppScreenTimeSessions.v1"
    private let maxStoredSessions = 300
    private let minimumSessionSeconds: TimeInterval = 1

    private let lock = NSLock()
    private var sessionStartedAt: Date?
    private var cachedSessions: [AppScreenTimeSession]?

    private init() {}

    // MARK: - Lifecycle

    func startSessionIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        if sessionStartedAt == nil {
            sessionStartedAt = Date()
        }
    }

    func endSessionIfNeeded() {
        lock.lock()
        guard let startedAt = sessionStartedAt else {
            lock.unlock()
            return
        }
        sessionStartedAt = nil
        lock.unlock()

        let endedAt = Date()
        let duration = endedAt.timeIntervalSince(startedAt)
        guard duration >= minimumSessionSeconds else { return }

        let session = AppScreenTimeSession(
            id: UUID().uuidString,
            startedAt: startedAt,
            endedAt: endedAt
        )
        var sessions = loadSessions()
        sessions.insert(session, at: 0)
        if sessions.count > maxStoredSessions {
            sessions = Array(sessions.prefix(maxStoredSessions))
        }
        saveSessions(sessions)
        NotificationCenter.default.post(name: .appScreenTimeDidChange, object: nil)
    }

    // MARK: - Queries

    func sessions(newestFirst: Bool = true) -> [AppScreenTimeSession] {
        let list = loadSessions()
        return newestFirst ? list : list.reversed()
    }

    /// Day-wise totals (newest first): Today, Yesterday, then older dates.
    func dailySummaries(includingCurrentSession: Bool = true) -> [AppScreenTimeDaySummary] {
        let calendar = Calendar.current
        var durationByDay: [Date: TimeInterval] = [:]
        var countByDay: [Date: Int] = [:]

        for session in loadSessions() {
            allocate(from: session.startedAt, to: session.endedAt, into: &durationByDay, counts: &countByDay, calendar: calendar)
        }

        if includingCurrentSession {
            lock.lock()
            let currentStart = sessionStartedAt
            lock.unlock()
            if let currentStart {
                allocate(from: currentStart, to: Date(), into: &durationByDay, counts: &countByDay, calendar: calendar)
            }
        }

        return durationByDay.keys
            .sorted(by: >)
            .compactMap { dayStart in
                let duration = durationByDay[dayStart] ?? 0
                guard duration >= minimumSessionSeconds else { return nil }
                return AppScreenTimeDaySummary(
                    dayStart: dayStart,
                    duration: duration,
                    sessionCount: countByDay[dayStart] ?? 0
                )
            }
    }

    /// Total of saved sessions, plus the in-progress session when the app is open.
    func totalDurationSeconds(includingCurrentSession: Bool = true) -> TimeInterval {
        dailySummaries(includingCurrentSession: includingCurrentSession)
            .reduce(0) { $0 + $1.duration }
    }

    func formattedTotal(includingCurrentSession: Bool = true) -> String {
        Self.formatDuration(totalDurationSeconds(includingCurrentSession: includingCurrentSession))
    }

    /// Splits a time range across calendar days (handles overnight sessions).
    private func allocate(
        from start: Date,
        to end: Date,
        into durationByDay: inout [Date: TimeInterval],
        counts: inout [Date: Int],
        calendar: Calendar
    ) {
        guard end > start else { return }
        var cursor = start
        var touchedDays = Set<Date>()
        while cursor < end {
            let dayStart = calendar.startOfDay(for: cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) else { break }
            let sliceEnd = min(end, nextDay)
            let slice = sliceEnd.timeIntervalSince(cursor)
            if slice > 0 {
                durationByDay[dayStart, default: 0] += slice
                touchedDays.insert(dayStart)
            }
            cursor = sliceEnd
        }
        for day in touchedDays {
            counts[day, default: 0] += 1
        }
    }

    // MARK: - Formatting

    /// Matches Screen Time design: `1h 18m 42s`, `1m 21s`, `10s`.
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return "\(h)h \(m)m \(s)s"
        }
        if m > 0 {
            return "\(m)m \(s)s"
        }
        return "\(s)s"
    }

    /// "Today", "Yesterday", or a localized date like "Jul 30, 2026".
    static func formatDayTitle(_ dayStart: Date, relativeTo now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(dayStart) {
            return AppL10n.t(.screenTimeToday)
        }
        if calendar.isDateInYesterday(dayStart) {
            return AppL10n.t(.screenTimeYesterday)
        }
        return formatDate(dayStart)
    }

    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMdyyyy")
        return formatter.string(from: date)
    }

    static func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "hh:mm a"
        let left = formatter.string(from: start).lowercased()
        let right = formatter.string(from: end).lowercased()
        return "\(left) - \(right)"
    }

    // MARK: - Persistence

    private func loadSessions() -> [AppScreenTimeSession] {
        lock.lock()
        if let cachedSessions {
            lock.unlock()
            return cachedSessions
        }
        lock.unlock()

        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            let decoded = try JSONDecoder().decode([AppScreenTimeSession].self, from: data)
            lock.lock()
            cachedSessions = decoded
            lock.unlock()
            return decoded
        } catch {
            return []
        }
    }

    private func saveSessions(_ sessions: [AppScreenTimeSession]) {
        lock.lock()
        cachedSessions = sessions
        lock.unlock()
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
