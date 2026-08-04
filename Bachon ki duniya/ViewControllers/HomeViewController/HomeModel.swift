//
//  HomeModel.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

import Foundation

// MARK: - Category Models
struct CategoryResponse: Codable {
    let status: String
    let code: String
    let data: [Category]
}

struct Category: Codable {
    let id: Int
    let img: String?  // Keep as optional
    let color: String
    let order: Int
    let hasSubcategories: Bool
    let directSeriesId: Int?
    let translations: [Translation]
    let subcategories: [Subcategory]?  // Optional - not used on home screen but needed for parsing
    
    enum CodingKeys: String, CodingKey {
        case id, img, color, order, translations, subcategories
        case hasSubcategories = "has_subcategories"
        case directSeriesId = "direct_series_id"
    }
    
    func getTranslation(for languageCode: String) -> Translation? {
        return translations.first(where: { $0.langCode == languageCode })
    }
}

// Subcategory model for parsing nested data
struct Subcategory: Codable {
    let id: Int
    let img: String?
    let color: String
    let order: Int
    let hasSubcategories: Bool
    let directSeriesId: Int?
    let translations: [Translation]
    
    enum CodingKeys: String, CodingKey {
        case id, img, color, order, translations
        case hasSubcategories = "has_subcategories"
        case directSeriesId = "direct_series_id"
    }
    
    func getTranslation(for languageCode: String) -> Translation? {
        return translations.first(where: { $0.langCode == languageCode })
    }
}

// MARK: - Episode Models
struct EpisodeResponse: Codable {
    let status: String?
    let code: String?
    let data: [Episode]
}

struct SeriesResponse: Codable {
    let status: String
    let code: String
    let data: [SeriesItem]
}

struct Episode: Codable {
    let id: Int
    let title: String
    let description: String
    let thumbnail: String?
    let audioUrl: String?
    let duration: String?
    let categoryId: Int
    let subcategoryId: Int?
    let order: Int
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, thumbnail, duration, order
        case audioUrl = "audio_url"
        case categoryId = "category_id"
        case subcategoryId = "subcategory_id"
        case createdAt = "created_at"
    }
}

struct SeriesItem: Codable {
    let id: Int
    let categoryId: Int
    let order: Int
    let img: String?
    let color: String
    let contentType: String
    let featured: Bool
    let translations: [Translation]
    
    enum CodingKeys: String, CodingKey {
        case id, order, img, color, featured, translations
        case categoryId = "category_id"
        case contentType = "content_type"
    }
    
    func getTranslation(for languageCode: String) -> Translation? {
        return translations.first(where: { $0.langCode == languageCode })
    }
}

struct StoryEpisodesResponse: Codable {
    let status: String
    let code: String
    let data: StoryContentData
}

struct StoryContentData: Codable {
    let id: Int
    let contentType: String
    let seasons: [StorySeason]
    
    enum CodingKeys: String, CodingKey {
        case id, seasons
        case contentType = "content_type"
    }
}

struct StorySeason: Codable {
    let id: Int
    let seasonNumber: Int
    let title: String
    let description: String?
    let episodes: [StoryEpisode]
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, episodes
        case seasonNumber = "season_number"
    }
}

struct StoryEpisode: Codable {
    let id: Int
    let episodeNumber: Int
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let htmlURL: String?
    let videoStatus: String?
    let isPremium: Bool
    let title: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case htmlURL = "html_url"
        case videoStatus = "video_status"
        case isPremium = "is_premium"
    }

    /// HTML game when `html_url` is set; otherwise treat as video when `video_url` is present.
    var isHTMLGame: Bool {
        guard let htmlURL, !htmlURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        return true
    }
}

struct SearchResponse: Decodable {
    let status: String
    let code: String
    let total: Int
    let data: [SearchEpisode]
}

struct SearchEpisode: Decodable {
    let id: Int
    let episodeNumber: Int?
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let videoStatus: String?
    let isPremium: Bool?
    /// Language of this search row (`lang_code` from API).
    let langCode: String?
    /// English language name (`lang_name`), e.g. "Sindhi".
    let langName: String?
    /// Native script language name (`native_name`).
    let nativeName: String?
    let direction: String?
    /// Episode title for this language row.
    let title: String?
    let description: String?
    var translations: [Translation]
    
    enum CodingKeys: String, CodingKey {
        case id, translations
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case videoStatus = "video_status"
        case isPremium = "is_premium"
        case langCode = "lang_code"
        case langName = "lang_name"
        case nativeName = "native_name"
        case direction
        case title
        case description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber)
        durationSecs = try container.decodeIfPresent(Int.self, forKey: .durationSecs)
        thumbnailURL = try container.decodeIfPresent(String.self, forKey: .thumbnailURL)
        videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL)
        videoStatus = try container.decodeIfPresent(String.self, forKey: .videoStatus)
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium)
        langCode = try container.decodeIfPresent(String.self, forKey: .langCode)
        langName = try container.decodeIfPresent(String.self, forKey: .langName)
        nativeName = try container.decodeIfPresent(String.self, forKey: .nativeName)
        direction = try container.decodeIfPresent(String.self, forKey: .direction)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        if let decodedTranslations = try container.decodeIfPresent([Translation].self, forKey: .translations) {
            translations = decodedTranslations
        } else if let langCode, let langName, let nativeName, let direction {
            translations = [
                Translation(
                    langCode: langCode,
                    langName: langName,
                    nativeName: nativeName,
                    direction: direction,
                    name: title ?? "",
                    description: description ?? ""
                )
            ]
        } else {
            translations = []
        }
    }
    
    /// Prefer English language name for the badge; fall back to native / code.
    var displayLanguageName: String {
        if let langName, !langName.isEmpty { return langName }
        if let nativeName, !nativeName.isEmpty { return nativeName }
        return langCode?.uppercased() ?? ""
    }
    
    var displayTitle: String {
        if let title, !title.isEmpty { return title }
        return getTranslation(for: LanguageManager.shared.currentLanguageCode)?.name
            ?? getTranslation(for: "en")?.name
            ?? ""
    }
    
    var displayDescription: String {
        if let description, !description.isEmpty { return description }
        return getTranslation(for: LanguageManager.shared.currentLanguageCode)?.description
            ?? getTranslation(for: "en")?.description
            ?? ""
    }
    
    func getTranslation(for languageCode: String) -> Translation? {
        return translations.first(where: { $0.langCode == languageCode })
    }
}

struct Translation: Codable {
    let langCode: String
    let langName: String
    let nativeName: String
    let direction: String
    let name: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case langCode = "lang_code"
        case langName = "lang_name"
        case nativeName = "native_name"
        case direction
        case name
        case title
        case description
    }
    
    init(langCode: String, langName: String, nativeName: String, direction: String, name: String, description: String) {
        self.langCode = langCode
        self.langName = langName
        self.nativeName = nativeName
        self.direction = direction
        self.name = name
        self.description = description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        langCode = try container.decode(String.self, forKey: .langCode)
        langName = try container.decode(String.self, forKey: .langName)
        nativeName = try container.decode(String.self, forKey: .nativeName)
        direction = try container.decode(String.self, forKey: .direction)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? container.decodeIfPresent(String.self, forKey: .title)
            ?? ""
        description = (try container.decodeIfPresent(String.self, forKey: .description)) ?? ""
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(langCode, forKey: .langCode)
        try container.encode(langName, forKey: .langName)
        try container.encode(nativeName, forKey: .nativeName)
        try container.encode(direction, forKey: .direction)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
    }
}

struct HomeItem {
    let id: Int
    let imageUrl: String
    let title: String
    let description: String
    let backgroundImageName: String
    let color: String
    let order: Int
    let hasSubcategories: Bool
    let directSeriesId: Int?
}

// MARK: - Home slider videos

struct HomeSliderVideosResponse: Decodable {
    let status: String
    let code: String
    let total: Int?
    let data: [HomeSliderVideo]
}

struct HomeSliderVideo: Decodable {
    let id: Int
    let episodeNumber: Int?
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let htmlURL: String?
    let videoStatus: String?
    let langCode: String?
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case htmlURL = "html_url"
        case videoStatus = "video_status"
        case langCode = "lang_code"
    }

    var displayTitle: String { title ?? "" }
}

// Add an enum for category types
enum CategoryType: String {
    case kidsStories = "Kids Stories"
    case islamicKnowledge = "Islamic Knowledge"
    case generalKnowledge = "General Knowledge"
    case kidsShows = "Kids Shows"
    case bedtimeStories = "Bedtime Stories"
    case growWell = "Grow Well"
    case poems = "Poems"
    case letsLearn = "Lets Learn"
    case riddles = "Riddles"
    
    // You can also use IDs if preferred
    var idRange: [Int] {
        switch self {
        case .kidsStories:
            return [1]
        case .islamicKnowledge:
            return [3]
        case .generalKnowledge:
            return [5]
        case .kidsShows:
            return [19]
        case .bedtimeStories:
            return [9]
        case .growWell:
            return [11]
        case .poems:
            return [13]
        case .letsLearn:
            return [15]
        case .riddles:
            return [17]
        }
    }
}
