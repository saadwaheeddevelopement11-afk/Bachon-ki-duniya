//
//  Network.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

import UIKit

// MARK: - API Manager
class APIManager {
    static let shared = APIManager()
    private let baseURL = "https://kidskahani.ideationtec.live"
    
    private init() {}
    
    func fetchCategories(languageCode: String, completion: @escaping (Result<[Category], Error>) -> Void) {
        let endpoint = "/categories?lang=\(languageCode)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            do {
                let categories = try self.decodeCategories(from: data)
                completion(.success(categories))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func fetchLanguages(completion: @escaping (Result<[Language], Error>) -> Void) {
        let endpoint = "/languages"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(LanguageResponse.self, from: data)
                // Filter only active languages
                let activeLanguages = response.data.filter { $0.isActive }
                completion(.success(activeLanguages))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

extension APIManager {
    
    // Fetch subcategories for a specific category
    func fetchSubcategories(
        categoryId: Int,
        languageCode: String,
        subcategoryId: Int? = nil,
        completion: @escaping (Result<[Subcategory], Error>) -> Void
    ) {
        guard var components = URLComponents(string: "https://kidskahani.ideationtec.live/subcategories/\(categoryId)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var queryItems = [URLQueryItem(name: "lang", value: languageCode)]
        if let subcategoryId {
            queryItems.append(URLQueryItem(name: "subcategoryid", value: "\(subcategoryId)"))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(SubcategoryResponse.self, from: data)
                if response.status == "success" {
                    completion(.success(response.data))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API returned error status"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch episodes for a specific category
    func fetchEpisodes(categoryId: Int, languageCode: String, completion: @escaping (Result<[Episode], Error>) -> Void) {
        // Adjust the endpoint based on your actual API
        // Option 1: If episodes endpoint exists
        let urlString = "https://kidskahani.ideationtec.live/categories/\(categoryId)/episodes?lang=\(languageCode)"
        
        // Option 2: If using content endpoint
        // let urlString = "https://kidskahani.ideationtec.live/content/\(categoryId)?lang=\(languageCode)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let episodes = try self.decodeEpisodes(from: data)
                completion(.success(episodes))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch episodes for a specific subcategory
    func fetchEpisodes(subcategoryId: Int, languageCode: String, completion: @escaping (Result<[Episode], Error>) -> Void) {
        let urlString = "https://kidskahani.ideationtec.live/subcategories/\(subcategoryId)/episodes?lang=\(languageCode)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let episodes = try self.decodeEpisodes(from: data)
                completion(.success(episodes))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch series for a selected subcategory/category id
    func fetchSeries(categoryId: Int, languageCode: String, completion: @escaping (Result<[SeriesItem], Error>) -> Void) {
        let urlString = "https://kidskahani.ideationtec.live/series?category_id=\(categoryId)&lang=\(languageCode)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(SeriesResponse.self, from: data)
                if response.status == "success" {
                    completion(.success(response.data.sorted(by: { $0.order < $1.order })))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API returned error status"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch episodes for a selected series/content id
    func fetchEpisodes(seriesId: Int, languageCode: String, completion: @escaping (Result<([StoryEpisode], String?), Error>) -> Void) {
        let urlString = "https://kidskahani.ideationtec.live/episodes/\(seriesId)?lang=\(languageCode)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(StoryEpisodesResponse.self, from: data)
                if response.status == "success" {
                    let seasonsSorted = response.data.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber })
                    let headerTitle = seasonsSorted.first?.title
                    let flattenedEpisodes = seasonsSorted
                        .flatMap { season in
                            season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })
                        }
                    completion(.success((flattenedEpisodes, headerTitle)))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API returned error status"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func searchEpisodes(query: String, completion: @escaping (Result<[SearchEpisode], Error>) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid query"])))
            return
        }
        
        let urlString = "https://kidskahani.ideationtec.live/search?q=\(encodedQuery)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let episodes = try self.decodeSearchEpisodes(from: data)
                completion(.success(episodes))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchLatestEpisodes(languageCode: String, completion: @escaping (Result<[LatestEpisodeCategory], Error>) -> Void) {
        let urlString = "https://kidskahani.ideationtec.live/latest-episodes?lang=\(languageCode)"

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(LatestEpisodesResponse.self, from: data)
                guard response.status == "success" else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "API returned error status"])))
                    return
                }
                completion(.success(response.data))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func decodeSearchEpisodes(from data: Data) throws -> [SearchEpisode] {
        let decoder = JSONDecoder()
        let payloads = splitTopLevelJSONObjects(from: data)
        var allEpisodes: [SearchEpisode] = []
        
        for payload in payloads {
            if let wrapped = try? decoder.decode(SearchResponse.self, from: payload), wrapped.status == "success" {
                allEpisodes.append(contentsOf: wrapped.data)
                continue
            }
            
            if let rawEpisodes = try? decoder.decode([SearchEpisode].self, from: payload) {
                allEpisodes.append(contentsOf: rawEpisodes)
                continue
            }
        }
        
        if allEpisodes.isEmpty {
            throw NSError(
                domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to decode search response"]
            )
        }
        
        // The search endpoint may return one row per language for the same episode id.
        // Merge those rows into one model so existing language lookup logic still works.
        var mergedById: [Int: SearchEpisode] = [:]
        for episode in allEpisodes {
            if var existing = mergedById[episode.id] {
                for translation in episode.translations where !existing.translations.contains(where: { $0.langCode == translation.langCode }) {
                    existing.translations.append(translation)
                }
                mergedById[episode.id] = existing
            } else {
                mergedById[episode.id] = episode
            }
        }
        
        return mergedById.values.sorted {
            ($0.episodeNumber ?? Int.max) < ($1.episodeNumber ?? Int.max)
        }
    }
    
    private func decodeCategories(from data: Data) throws -> [Category] {
        let decoder = JSONDecoder()
        let payloads = splitTopLevelJSONObjects(from: data)
        var allCategories: [Category] = []
        
        for payload in payloads {
            if let wrapped = try? decoder.decode(CategoryResponse.self, from: payload), wrapped.status == "success" {
                allCategories.append(contentsOf: wrapped.data)
                continue
            }
            
            if let raw = try? decoder.decode([Category].self, from: payload) {
                allCategories.append(contentsOf: raw)
                continue
            }
        }
        
        if allCategories.isEmpty {
            throw NSError(
                domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to decode categories response"]
            )
        }
        
        // If the backend duplicates top-level JSON payloads, keep the first occurrence per id.
        var seen = Set<Int>()
        let deduped = allCategories.filter { seen.insert($0.id).inserted }
        
        return deduped.sorted(by: { $0.order < $1.order })
    }
    
    private func decodeEpisodes(from data: Data) throws -> [Episode] {
        let decoder = JSONDecoder()
        let payloads = splitTopLevelJSONObjects(from: data)
        var allEpisodes: [Episode] = []
        
        for payload in payloads {
            if let wrapped = try? decoder.decode(EpisodeResponse.self, from: payload) {
                allEpisodes.append(contentsOf: wrapped.data)
                continue
            }
            
            if let rawEpisodes = try? decoder.decode([Episode].self, from: payload) {
                allEpisodes.append(contentsOf: rawEpisodes)
                continue
            }
            
            // Some category endpoints return story-like wrapped payload:
            // { status, code, data: { seasons: [{ episodes: [...] }] } }
            if let storyWrapped = try? decoder.decode(StoryEpisodesResponse.self, from: payload) {
                let mapped = storyWrapped.data.seasons
                    .sorted(by: { $0.seasonNumber < $1.seasonNumber })
                    .flatMap { season in
                        season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })
                    }
                    .map { storyEpisode in
                        Episode(
                            id: storyEpisode.id,
                            title: storyEpisode.title,
                            description: storyEpisode.description,
                            thumbnail: storyEpisode.thumbnailURL,
                            audioUrl: nil,
                            duration: storyEpisode.durationSecs.map(String.init),
                            categoryId: 0,
                            subcategoryId: nil,
                            order: storyEpisode.episodeNumber,
                            createdAt: nil
                        )
                    }
                allEpisodes.append(contentsOf: mapped)
                continue
            }
        }
        
        if !allEpisodes.isEmpty {
            // Keep backend ordering intent while removing duplicated episodes if payload repeats.
            let sorted = allEpisodes.sorted(by: { $0.order < $1.order })
            var seenIds = Set<Int>()
            return sorted.filter { seenIds.insert($0.id).inserted }
        }
        
        throw NSError(
            domain: "",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to decode episodes response"]
        )
    }
    
    private func splitTopLevelJSONObjects(from data: Data) -> [Data] {
        guard let text = String(data: data, encoding: .utf8) else { return [data] }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{" else { return [data] }
        
        var depth = 0
        var inString = false
        var isEscaped = false
        var startIndex: String.Index?
        var chunks: [Data] = []
        
        for charIndex in trimmed.indices {
            let char = trimmed[charIndex]
            if inString {
                if isEscaped {
                    isEscaped = false
                } else if char == "\\" {
                    isEscaped = true
                } else if char == "\"" {
                    inString = false
                }
                continue
            }
            
            if char == "\"" {
                inString = true
            } else if char == "{" {
                if depth == 0 {
                    startIndex = charIndex
                }
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0, let start = startIndex {
                    let objectString = String(trimmed[start...charIndex])
                    if let objectData = objectString.data(using: .utf8) {
                        chunks.append(objectData)
                    }
                    startIndex = nil
                }
            }
        }
        
        return chunks.isEmpty ? [data] : chunks
    }
}

// Response wrapper for subcategories
struct SubcategoryResponse: Codable {
    let status: String
    let code: String
    let data: [Subcategory]
}

struct LatestEpisodesResponse: Codable {
    let status: String
    let code: String
    let total: Int
    let data: [LatestEpisodeCategory]
}

struct LatestEpisodeCategory: Codable {
    let categoryId: Int
    let categoryName: String
    let episodes: [LatestEpisode]

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case episodes
    }
}

struct LatestEpisode: Codable {
    let id: Int
    let episodeNumber: Int?
    let durationSecs: Int?
    let thumbnailURL: String?
    let videoURL: String?
    let htmlURL: String?
    let videoStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case episodeNumber = "episode_number"
        case durationSecs = "duration_secs"
        case thumbnailURL = "thumbnail_url"
        case videoURL = "video_url"
        case htmlURL = "html_url"
        case videoStatus = "video_status"
    }
}

extension Notification.Name {
    /// Posted after the user selects a new app language (`LanguageManager.saveLanguage`).
    static let languageDidChange = Notification.Name("LanguageChanged")
}

// MARK: - Language Manager
class LanguageManager {
    static let shared = LanguageManager()
    private let userDefaults = UserDefaults.standard
    private let selectedLanguageKey = "selected_language_code"
    private let selectedLanguageNameKey = "selected_language_name"
    private let selectedLanguageDirectionKey = "selected_language_direction"
    
    private init() {}
    
    var currentLanguageCode: String {
        get {
            return userDefaults.string(forKey: selectedLanguageKey) ?? "en"
        }
        set {
            userDefaults.set(newValue, forKey: selectedLanguageKey)
        }
    }
    
    var currentLanguageName: String? {
        get {
            return userDefaults.string(forKey: selectedLanguageNameKey)
        }
        set {
            userDefaults.set(newValue, forKey: selectedLanguageNameKey)
        }
    }
    
    var currentLanguageDirection: String? {
        get {
            return userDefaults.string(forKey: selectedLanguageDirectionKey)
        }
        set {
            userDefaults.set(newValue, forKey: selectedLanguageDirectionKey)
        }
    }
    
    func saveLanguage(_ language: Language) {
        currentLanguageCode = language.languageCode
        currentLanguageName = language.nativeName
        currentLanguageDirection = language.direction
        applyLayoutDirectionToApplication()
    }
    
    func isRTL() -> Bool {
        return currentLanguageDirection == "RTL"
    }
    
    /// Applies LTR/RTL to the appearance proxy, key windows, and the entire view hierarchy so existing screens flip reliably (not only newly created views).
    func applyLayoutDirectionToApplication() {
        let attr: UISemanticContentAttribute = isRTL() ? .forceRightToLeft : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = attr
        
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.semanticContentAttribute = attr
                if let root = window.rootViewController?.view {
                    applySemanticContentAttribute(attr, toSubtreeStartingAt: root)
                }
                window.setNeedsLayout()
                window.layoutIfNeeded()
            }
        }
    }
    
    private func applySemanticContentAttribute(_ attr: UISemanticContentAttribute, toSubtreeStartingAt view: UIView) {
        view.semanticContentAttribute = attr
        for sub in view.subviews {
            applySemanticContentAttribute(attr, toSubtreeStartingAt: sub)
        }
    }
    
    /// Refreshes the localized navigation title for a home category after language change.
    func fetchLocalizedCategoryTitle(categoryId: Int, completion: @escaping (String?) -> Void) {
        guard categoryId > 0 else {
            completion(nil)
            return
        }
        let lang = currentLanguageCode
        APIManager.shared.fetchCategories(languageCode: lang) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let categories):
                    guard let category = categories.first(where: { $0.id == categoryId }) else {
                        completion(nil)
                        return
                    }
                    let name = category.getTranslation(for: lang)?.name
                        ?? category.getTranslation(for: "en")?.name
                    completion(name)
                case .failure:
                    completion(nil)
                }
            }
        }
    }
}
