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
                let decoder = JSONDecoder()
                let response = try decoder.decode(CategoryResponse.self, from: data)
                // Sort categories by order
                let sortedCategories = response.data.sorted(by: { $0.order < $1.order })
                completion(.success(sortedCategories))
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
    func fetchSubcategories(categoryId: Int, languageCode: String, completion: @escaping (Result<[Subcategory], Error>) -> Void) {
        let urlString = "https://kidskahani.ideationtec.live/subcategories/\(categoryId)?lang=\(languageCode)"
        
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
    func fetchEpisodes(seriesId: Int, languageCode: String, completion: @escaping (Result<[StoryEpisode], Error>) -> Void) {
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
                    let flattenedEpisodes = response.data.seasons
                        .sorted(by: { $0.seasonNumber < $1.seasonNumber })
                        .flatMap { season in
                            season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })
                        }
                    completion(.success(flattenedEpisodes))
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
                let response = try JSONDecoder().decode(SearchResponse.self, from: data)
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
    
    private func decodeEpisodes(from data: Data) throws -> [Episode] {
        let decoder = JSONDecoder()
        let payload = firstJSONObjectDataIfConcatenated(from: data) ?? data
        
        if let wrapped = try? decoder.decode(EpisodeResponse.self, from: payload) {
            // Some endpoints omit `status` entirely; trust decoded data when present.
            return wrapped.data
        }
        
        if let rawEpisodes = try? decoder.decode([Episode].self, from: payload) {
            return rawEpisodes
        }

        // Some category endpoints return story-like wrapped payload:
        // { status, code, data: { seasons: [{ episodes: [...] }] } }
        if let storyWrapped = try? decoder.decode(StoryEpisodesResponse.self, from: payload) {
            return storyWrapped.data.seasons
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
        }
        
        throw NSError(
            domain: "",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to decode episodes response"]
        )
    }
    
    private func firstJSONObjectDataIfConcatenated(from data: Data) -> Data? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "{" else { return nil }
        
        var depth = 0
        var inString = false
        var isEscaped = false
        
        for (index, char) in trimmed.enumerated() {
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
                depth += 1
            } else if char == "}" {
                depth -= 1
                if depth == 0 {
                    let endIndex = trimmed.index(trimmed.startIndex, offsetBy: index)
                    let firstObject = String(trimmed[...endIndex])
                    return firstObject.data(using: .utf8)
                }
            }
        }
        
        return nil
    }
}

// Response wrapper for subcategories
struct SubcategoryResponse: Codable {
    let status: String
    let code: String
    let data: [Subcategory]
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
        
        // Update app's semantic content direction
        if language.direction == "RTL" {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .forceLeftToRight
        }
    }
    
    func isRTL() -> Bool {
        return currentLanguageDirection == "RTL"
    }
}
