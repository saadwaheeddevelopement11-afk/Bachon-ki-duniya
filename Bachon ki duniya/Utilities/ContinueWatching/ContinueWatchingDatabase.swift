import Foundation
import SQLite3

/// SQLite persistence for continue watching (`VideoDatabase` table).
final class ContinueWatchingDatabase {

    static let shared = ContinueWatchingDatabase()

    private let queue = DispatchQueue(label: "com.bachonkiduniya.continuewatching.db", qos: .userInitiated)
    private var db: OpaquePointer?

    private init() {
        queue.sync {
            openDatabase()
            createTableIfNeeded()
        }
    }

    func upsert(
        videoId: Int,
        title: String?,
        durationMs: Int64,
        imageURL: String?,
        lastPositionMs: Int64,
        durationPlayedMs: Int64,
        videoURL: String,
        updatedOnline: Int = 0
    ) {
        queue.async { [weak self] in
            guard let self else { return }
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            let sql = """
            INSERT INTO VideoDatabase (
                videoId, title, duration, img, last_position, duration_played,
                system_time, updated, video_url
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(videoId) DO UPDATE SET
                title = excluded.title,
                duration = CASE WHEN excluded.duration > 0 THEN excluded.duration ELSE VideoDatabase.duration END,
                img = excluded.img,
                last_position = excluded.last_position,
                duration_played = excluded.duration_played,
                system_time = excluded.system_time,
                updated = excluded.updated,
                video_url = excluded.video_url;
            """
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(statement) }

            sqlite3_bind_int(statement, 1, Int32(videoId))
            bindOptionalText(statement, index: 2, value: title)
            sqlite3_bind_int64(statement, 3, durationMs)
            bindOptionalText(statement, index: 4, value: imageURL)
            sqlite3_bind_int64(statement, 5, lastPositionMs)
            sqlite3_bind_int64(statement, 6, durationPlayedMs)
            sqlite3_bind_int64(statement, 7, now)
            sqlite3_bind_int(statement, 8, Int32(updatedOnline))
            bindText(statement, index: 9, value: videoURL)

            sqlite3_step(statement)
        }
    }

    func fetchRecent(limit: Int = 20, completion: @escaping ([ContinueWatchingRecord]) -> Void) {
        queue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            let sql = """
            SELECT id, videoId, title, duration, img, last_position, duration_played,
                   system_time, updated, video_url
            FROM VideoDatabase
            WHERE duration_played > 0 OR last_position > 0
            ORDER BY system_time DESC
            LIMIT ?;
            """
            var statement: OpaquePointer?
            var rows: [ContinueWatchingRecord] = []
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    rows.append(self.readRow(statement))
                }
            }
            sqlite3_finalize(statement)
            DispatchQueue.main.async { completion(rows) }
        }
    }

    func delete(videoId: Int) {
        queue.async { [weak self] in
            guard let self else { return }
            let sql = "DELETE FROM VideoDatabase WHERE videoId = ?;"
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(statement) }
            sqlite3_bind_int(statement, 1, Int32(videoId))
            sqlite3_step(statement)
        }
    }

    // MARK: - Private

    private func openDatabase() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoDatabase.sqlite")
        if sqlite3_open(url.path, &db) != SQLITE_OK {
            print("ContinueWatching DB open failed")
        }
    }

    private func createTableIfNeeded() {
        let sql = """
        CREATE TABLE IF NOT EXISTS VideoDatabase (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            videoId INTEGER NOT NULL UNIQUE,
            title TEXT,
            duration INTEGER NOT NULL DEFAULT 0,
            img TEXT,
            last_position INTEGER NOT NULL DEFAULT 0,
            duration_played INTEGER NOT NULL DEFAULT 0,
            system_time INTEGER NOT NULL DEFAULT 0,
            updated INTEGER NOT NULL DEFAULT 0,
            video_url TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_video_id ON VideoDatabase(videoId);
        CREATE INDEX IF NOT EXISTS idx_last_position ON VideoDatabase(last_position);
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private func readRow(_ statement: OpaquePointer?) -> ContinueWatchingRecord {
        ContinueWatchingRecord(
            id: sqlite3_column_int64(statement, 0),
            videoId: Int(sqlite3_column_int(statement, 1)),
            title: optionalString(statement, index: 2),
            durationMs: sqlite3_column_int64(statement, 3),
            imageURL: optionalString(statement, index: 4),
            lastPositionMs: sqlite3_column_int64(statement, 5),
            durationPlayedMs: sqlite3_column_int64(statement, 6),
            systemTimeMs: sqlite3_column_int64(statement, 7),
            updatedOnline: Int(sqlite3_column_int(statement, 8)),
            videoURL: optionalString(statement, index: 9) ?? ""
        )
    }

    private func bindText(_ statement: OpaquePointer?, index: Int32, value: String) {
        sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, SQLITE_TRANSIENT)
    }

    private func bindOptionalText(_ statement: OpaquePointer?, index: Int32, value: String?) {
        if let value {
            bindText(statement, index: index, value: value)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func optionalString(_ statement: OpaquePointer?, index: Int32) -> String? {
        guard let cString = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cString)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
