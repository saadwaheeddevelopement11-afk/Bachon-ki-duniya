//
//  LanguagesModel.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 30/03/2026.
//

// MARK: - Language Models
struct LanguageResponse: Codable {
    let status: String
    let code: String
    let data: [Language]
}

struct Language: Codable {
    let id: Int
    let code: String?
    let code3: String
    let name: String
    let nativeName: String
    let direction: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case code3
        case name
        case nativeName = "native_name"
        case direction
        case isActive = "is_active"
    }
    
    // Helper computed property to get the language code
    var languageCode: String {
        return code ?? code3
    }
}
