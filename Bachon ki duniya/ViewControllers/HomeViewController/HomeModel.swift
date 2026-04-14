//
//  HomeModel.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

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
    let translations: [Translation]
    let subcategories: [Subcategory]?  // Optional - not used on home screen but needed for parsing
    
    enum CodingKeys: String, CodingKey {
        case id, img, color, order, translations, subcategories
        case hasSubcategories = "has_subcategories"
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
    let translations: [Translation]
    
    enum CodingKeys: String, CodingKey {
        case id, img, color, order, translations
        case hasSubcategories = "has_subcategories"
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
        case videoStatus = "video_status"
        case isPremium = "is_premium"
    }
}

struct SearchResponse: Codable {
    let status: String
    let code: String
    let total: Int
    let data: [SearchEpisode]
}

struct SearchEpisode: Codable {
    let id: Int
    let episodeNumber: Int?
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let videoStatus: String?
    let isPremium: Bool?
    let translations: [Translation]
    
    enum CodingKeys: String, CodingKey {
        case id, translations
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case videoStatus = "video_status"
        case isPremium = "is_premium"
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
        case description
    }
}

struct HomeItem {
    let id: Int
    let imageUrl: String
    let title: String
    let description: String
    let color: String
    let order: Int
    let hasSubcategories: Bool
}

// Add an enum for category types
enum CategoryType: String {
    case kidsStories = "Kids Stories"
    case islamicKnowledge = "Islamic Knowledge"
    case generalKnowledge = "General Knowledge"
    case kidsShows = "Kids Shows"
    case bedtimeStories = "Bedtime Stories & Poems"
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
