//
//  BookmarkStore.swift
//  Bachon ki duniya
//

import Foundation

extension Notification.Name {
    static let bookmarksDidChange = Notification.Name("BookmarksDidChange")
}

/// Local cache of bookmarked episode IDs + full episode payloads from GET /bookmarks/{msisdn}.
enum BookmarkStore {

    private static let idsKey = "bookmark_episode_ids"
    private static let itemsKey = "bookmark_episodes_json"

    // MARK: - Local reads

    static func bookmarkedIds() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: idsKey) as? [Int] ?? []
        return Set(array)
    }

    static func isBookmarked(_ episodeId: Int) -> Bool {
        bookmarkedIds().contains(episodeId)
    }

    static func allBookmarks() -> [BookmarkEpisode] {
        guard let data = UserDefaults.standard.data(forKey: itemsKey) else { return [] }
        return (try? JSONDecoder().decode([BookmarkEpisode].self, from: data)) ?? []
    }

    // MARK: - Local writes

    private static func saveIds(_ ids: Set<Int>) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: idsKey)
    }

    private static func saveItems(_ items: [BookmarkEpisode]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: idsKey)
        UserDefaults.standard.removeObject(forKey: itemsKey)
        notifyChange()
    }

    private static func applyServerIds(_ ids: [Int]) {
        saveIds(Set(ids))
        let kept = allBookmarks().filter { ids.contains($0.id) }
        saveItems(kept)
        notifyChange()
    }

    private static func upsertLocalItem(id: Int, title: String?, description: String?, thumbnailURL: String?, videoURL: String?) {
        var items = allBookmarks()
        if let index = items.firstIndex(where: { $0.id == id }) {
            let existing = items[index]
            items[index] = BookmarkEpisode(
                id: id,
                episodeNumber: existing.episodeNumber,
                durationSecs: existing.durationSecs,
                thumbnailURL: thumbnailURL ?? existing.thumbnailURL,
                videoURL: videoURL ?? existing.videoURL,
                htmlURL: existing.htmlURL,
                videoStatus: existing.videoStatus,
                title: title ?? existing.title,
                description: description ?? existing.description,
                bookmarkedAt: existing.bookmarkedAt
            )
        } else {
            items.insert(
                BookmarkEpisode(
                    id: id,
                    episodeNumber: nil,
                    durationSecs: nil,
                    thumbnailURL: thumbnailURL,
                    videoURL: videoURL,
                    htmlURL: nil,
                    videoStatus: nil,
                    title: title,
                    description: description,
                    bookmarkedAt: nil
                ),
                at: 0
            )
        }
        saveItems(items)
    }

    private static func removeLocalItem(id: Int) {
        saveItems(allBookmarks().filter { $0.id != id })
    }

    private static func notifyChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .bookmarksDidChange, object: nil)
        }
    }

    // MARK: - Network

    static func syncFromServer(completion: ((Bool) -> Void)? = nil) {
        guard let msisdn = UserSession.msisdnDigits else {
            completion?(false)
            return
        }
        let lang = LanguageManager.shared.currentLanguageCode
        APIManager.shared.fetchBookmarks(msisdn: msisdn, languageCode: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    guard response.isSuccess else {
                        completion?(false)
                        return
                    }
                    let items = response.data ?? []
                    saveItems(items)
                    saveIds(Set(items.map(\.id)))
                    notifyChange()
                    completion?(true)
                case .failure:
                    completion?(false)
                }
            }
        }
    }

    /// Optimistically toggles local state, then calls add/remove API and reconciles with `episode_ids`.
    static func toggle(
        episodeId: Int,
        title: String? = nil,
        description: String? = nil,
        thumbnailURL: String? = nil,
        videoURL: String? = nil,
        completion: ((Result<Bool, Error>) -> Void)? = nil
    ) {
        guard let msisdn = UserSession.msisdnDigits else {
            completion?(.failure(NSError(
                domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Please sign in to use bookmarks."]
            )))
            return
        }

        let currentlyBookmarked = isBookmarked(episodeId)
        var ids = bookmarkedIds()

        if currentlyBookmarked {
            ids.remove(episodeId)
            saveIds(ids)
            removeLocalItem(id: episodeId)
            notifyChange()

            APIManager.shared.removeBookmark(msisdn: msisdn, episodeId: episodeId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.isSuccess, let serverIds = response.episodeIds {
                            applyServerIds(serverIds)
                            completion?(.success(false))
                        } else if response.isSuccess {
                            completion?(.success(false))
                        } else {
                            // Revert
                            var reverted = bookmarkedIds()
                            reverted.insert(episodeId)
                            saveIds(reverted)
                            upsertLocalItem(
                                id: episodeId,
                                title: title,
                                description: description,
                                thumbnailURL: thumbnailURL,
                                videoURL: videoURL
                            )
                            notifyChange()
                            completion?(.failure(NSError(
                                domain: "",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: response.message ?? "Could not remove bookmark"]
                            )))
                        }
                    case .failure(let error):
                        var reverted = bookmarkedIds()
                        reverted.insert(episodeId)
                        saveIds(reverted)
                        upsertLocalItem(
                            id: episodeId,
                            title: title,
                            description: description,
                            thumbnailURL: thumbnailURL,
                            videoURL: videoURL
                        )
                        notifyChange()
                        completion?(.failure(error))
                    }
                }
            }
        } else {
            ids.insert(episodeId)
            saveIds(ids)
            upsertLocalItem(
                id: episodeId,
                title: title,
                description: description,
                thumbnailURL: thumbnailURL,
                videoURL: videoURL
            )
            notifyChange()

            APIManager.shared.addBookmark(msisdn: msisdn, episodeId: episodeId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.isSuccess, let serverIds = response.episodeIds {
                            applyServerIds(serverIds)
                            // Keep optimistic item metadata if server list sync hasn't run yet.
                            if serverIds.contains(episodeId),
                               !allBookmarks().contains(where: { $0.id == episodeId }) {
                                upsertLocalItem(
                                    id: episodeId,
                                    title: title,
                                    description: description,
                                    thumbnailURL: thumbnailURL,
                                    videoURL: videoURL
                                )
                                notifyChange()
                            }
                            completion?(.success(true))
                        } else if response.isSuccess {
                            completion?(.success(true))
                        } else {
                            var reverted = bookmarkedIds()
                            reverted.remove(episodeId)
                            saveIds(reverted)
                            removeLocalItem(id: episodeId)
                            notifyChange()
                            completion?(.failure(NSError(
                                domain: "",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: response.message ?? "Could not add bookmark"]
                            )))
                        }
                    case .failure(let error):
                        var reverted = bookmarkedIds()
                        reverted.remove(episodeId)
                        saveIds(reverted)
                        removeLocalItem(id: episodeId)
                        notifyChange()
                        completion?(.failure(error))
                    }
                }
            }
        }
    }
}
