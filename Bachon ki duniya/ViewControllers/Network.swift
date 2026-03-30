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
