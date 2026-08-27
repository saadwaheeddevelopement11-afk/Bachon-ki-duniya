//
//  BookmarkModels.swift
//  Bachon ki duniya
//

import Foundation

struct BookmarkMutationResponse: Decodable {
    let status: String
    let code: String
    let message: String?
    let episodeIds: [Int]?

    enum CodingKeys: String, CodingKey {
        case status, code, message
        case episodeIds = "episode_ids"
    }

    var isSuccess: Bool { status.lowercased() == "success" }
}

struct BookmarksListResponse: Decodable {
    let status: String
    let code: String
    let total: Int?
    let data: [BookmarkEpisode]?

    var isSuccess: Bool { status.lowercased() == "success" }
}

struct BookmarkEpisode: Codable, Equatable {
    let id: Int
    let episodeNumber: Int?
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let htmlURL: String?
    let videoStatus: String?
    let title: String?
    let description: String?
    let bookmarkedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case htmlURL = "html_url"
        case videoStatus = "video_status"
        case bookmarkedAt = "bookmarked_at"
    }

    var displayTitle: String {
        let value = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? "Episode \(id)" : value
    }

    var displayDescription: String {
        description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
