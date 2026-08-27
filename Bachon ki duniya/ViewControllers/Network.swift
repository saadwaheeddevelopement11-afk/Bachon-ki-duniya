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

    func fetchHomeSliderVideos(
        languageCode: String,
        limit: Int = 5,
        completion: @escaping (Result<[HomeSliderVideo], Error>) -> Void
    ) {
        let endpoint = "/home-slider-videos?lang=\(languageCode)&limit=\(limit)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let videos = try self.decodeHomeSliderVideos(from: data)
                completion(.success(videos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    /// `GET /profile/{msisdn}` — e.g. `/profile/923369790892`
    func fetchProfile(
        msisdn: String,
        completion: @escaping (Result<UserProfile, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard UserSession.isValidPakistanMSISDN(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        let endpoint = "/profile/\(digits)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decoder = JSONDecoder()
                let wrapped = try decoder.decode(UserProfileAPIResponse.self, from: data)
                guard wrapped.status.lowercased() == "success" else {
                    completion(.failure(NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Profile request failed (\(wrapped.code))"]
                    )))
                    return
                }
                completion(.success(wrapped.data))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func decodeHomeSliderVideos(from data: Data) throws -> [HomeSliderVideo] {
        let decoder = JSONDecoder()
        let payloads = splitTopLevelJSONObjects(from: data)
        var all: [HomeSliderVideo] = []

        for payload in payloads {
            if let wrapped = try? decoder.decode(HomeSliderVideosResponse.self, from: payload),
               wrapped.status == "success" {
                all.append(contentsOf: wrapped.data)
                continue
            }
            if let raw = try? decoder.decode([HomeSliderVideo].self, from: payload) {
                all.append(contentsOf: raw)
            }
        }

        guard !all.isEmpty else {
            throw NSError(
                domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to decode home slider videos"]
            )
        }

        var seen = Set<Int>()
        return all.filter { seen.insert($0.id).inserted }
    }

    // MARK: - OTP

    func generateOTP(phone: String, completion: @escaping (Result<OTPGenerateResponse, Error>) -> Void) {
        let normalized = UserSession.normalizePhoneDigits(phone)
        postOTP(path: "/otp/generate", body: ["phone": normalized], completion: completion)
    }

    func verifyOTP(phone: String, otp: String, completion: @escaping (Result<OTPVerifyResponse, Error>) -> Void) {
        let normalized = UserSession.normalizePhoneDigits(phone)
        postOTP(path: "/otp/verify", body: ["phone": normalized, "otp": otp], completion: completion)
    }

    private func postOTP<T: Decodable>(
        path: String,
        body: [String: String],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Parental Controls

    func fetchParentalStatus(
        msisdn: String,
        completion: @escaping (Result<ParentalStatusData, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let url = URL(string: baseURL + "/parental/status/\(digits)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let wrapped = try JSONDecoder().decode(ParentalStatusAPIResponse.self, from: data)
                guard (wrapped.status.lowercased() == "success" || wrapped.code == "000"),
                      let status = wrapped.data else {
                    completion(.failure(NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unable to load parental status"]
                    )))
                    return
                }
                completion(.success(status))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func setupParentalControls(
        msisdn: String,
        pin: String,
        dailyLimitMinutes: Int,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/setup",
            body: [
                "msisdn": msisdnValue,
                "pin": pin,
                "daily_limit_minutes": dailyLimitMinutes
            ],
            completion: completion
        )
    }

    func verifyParentalPIN(
        msisdn: String,
        pin: String,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/verify-pin",
            body: ["msisdn": msisdnValue, "pin": pin],
            completion: completion
        )
    }

    func disableParentalControls(
        msisdn: String,
        pin: String,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/disable",
            body: ["msisdn": msisdnValue, "pin": pin],
            completion: completion
        )
    }

    func updateParentalControls(
        msisdn: String,
        currentPIN: String,
        newPIN: String?,
        dailyLimitMinutes: Int,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        var body: [String: Any] = [
            "msisdn": msisdnValue,
            "current_pin": currentPIN,
            "daily_limit_minutes": dailyLimitMinutes
        ]
        if let newPIN, !newPIN.isEmpty {
            body["new_pin"] = newPIN
        } else {
            body["new_pin"] = currentPIN
        }
        postParentalJSON(path: "/parental/update", body: body, completion: completion)
    }

    func lockParentalCategory(
        msisdn: String,
        categoryId: Int,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/lock-category",
            body: ["msisdn": msisdnValue, "category_id": categoryId],
            completion: completion
        )
    }

    func unlockParentalCategory(
        msisdn: String,
        categoryId: Int,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/unlock-category",
            body: ["msisdn": msisdnValue, "category_id": categoryId],
            completion: completion
        )
    }

    func requestParentalPINReset(
        phone: String,
        completion: @escaping (Result<ParentalResetPINRequestResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(phone)
        postParentalJSON(
            path: "/parental/reset-pin/request",
            body: ["phone": digits],
            completion: completion
        )
    }

    func confirmParentalPINReset(
        msisdn: String,
        otp: String,
        newPIN: String,
        completion: @escaping (Result<ParentalMessageResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/parental/reset-pin/confirm",
            body: [
                "msisdn": msisdnValue,
                "otp": otp,
                "new_pin": newPIN
            ],
            completion: completion
        )
    }

    private func postParentalJSON<T: Decodable>(
        path: String,
        body: [String: Any],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Bookmarks

    func addBookmark(
        msisdn: String,
        episodeId: Int,
        completion: @escaping (Result<BookmarkMutationResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/bookmarks/add",
            body: ["msisdn": msisdnValue, "episode_id": episodeId],
            completion: completion
        )
    }

    func removeBookmark(
        msisdn: String,
        episodeId: Int,
        completion: @escaping (Result<BookmarkMutationResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard let msisdnValue = Int64(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        postParentalJSON(
            path: "/bookmarks/remove",
            body: ["msisdn": msisdnValue, "episode_id": episodeId],
            completion: completion
        )
    }

    func fetchBookmarks(
        msisdn: String,
        languageCode: String,
        completion: @escaping (Result<BookmarksListResponse, Error>) -> Void
    ) {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard UserSession.isValidPakistanMSISDN(digits) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid MSISDN"])))
            return
        }
        let lang = languageCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = "/bookmarks/\(digits)?lang=\(lang.isEmpty ? "en" : lang)"
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(BookmarksListResponse.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - OTP Models

struct OTPGenerateResponse: Decodable {
    let status: String
    let code: String
    let message: String?
    let data: OTPGenerateData?
}

struct OTPGenerateData: Decodable {
    let phone: String?
    let expiresIn: String?

    enum CodingKeys: String, CodingKey {
        case phone
        case expiresIn = "expires_in"
    }
}

struct OTPVerifyResponse: Decodable {
    let status: String
    let code: String
    let message: String?
    let data: OTPVerifyData?
}

struct OTPVerifyData: Decodable {
    let phone: String?
    // Keep flexible — backend may add token/user fields later.
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
                let episodes = try self.decodeStoryEpisodes(from: data)
                completion(.success(episodes))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    private func decodeStoryEpisodes(from data: Data) throws -> [StoryEpisode] {
        let decoder = JSONDecoder()
        let payloads = splitTopLevelJSONObjects(from: data)
        var flattened: [StoryEpisode] = []

        for payload in payloads {
            guard let wrapped = try? decoder.decode(StoryEpisodesResponse.self, from: payload),
                  wrapped.status == "success" else { continue }
            let seasonsSorted = wrapped.data.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber })
            flattened.append(contentsOf: seasonsSorted.flatMap { season in
                season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })
            })
        }

        guard !flattened.isEmpty else {
            throw NSError(
                domain: "",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to decode story episodes response"]
            )
        }

        var seen = Set<Int>()
        return flattened.filter { seen.insert($0.id).inserted }
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
        
        // API may duplicate the whole JSON payload and returns one row per language
        // for the same episode id. Keep each language row (different video_url) and
        // only drop exact duplicates of (id + lang_code).
        var seen = Set<String>()
        let deduped = allEpisodes.filter { episode in
            let key = "\(episode.id)|\(episode.langCode ?? "")|\(episode.videoURL ?? "")"
            return seen.insert(key).inserted
        }
        
        return deduped.sorted {
            if $0.id != $1.id { return $0.id < $1.id }
            return ($0.langName ?? "") < ($1.langName ?? "")
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
        currentLanguageName = language.name
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
