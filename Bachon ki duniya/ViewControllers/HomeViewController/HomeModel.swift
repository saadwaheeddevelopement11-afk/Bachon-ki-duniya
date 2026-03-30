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
    let img: String
    let color: String
    let order: Int
    let translations: [Translation]
    
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

// MARK: - Home Item Model
struct HomeItem {
    let id: Int
    let imageUrl: String
    let title: String
    let description: String
    let color: String
    let order: Int
}
