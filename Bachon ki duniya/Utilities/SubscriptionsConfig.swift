//
//  SubscriptionsConfig.swift
//  Bachon ki duniya
//

import Foundation

/// Web subscriptions page opened from Profile.
/// Set `baseURLString` when backend provides the URL; MSISDN (and optional token) are appended as query items.
enum SubscriptionsConfig {
    /// Replace with the backend subscriptions URL when available (e.g. "https://example.com/subscribe").
    static var baseURLString: String = ""

    /// Query keys the web page can use to identify the user. Align with backend/Android when provided.
    static let msisdnQueryKey = "msisdn"
    static let tokenQueryKey = "token"

    /// Optional auth/session token from backend later. Empty for now.
    static var userToken: String = ""

    static func subscriptionURL() -> URL? {
        let trimmed = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var components = URLComponents(string: trimmed) else { return nil }

        var items = components.queryItems ?? []
        if let msisdn = UserSession.msisdnDigits, !msisdn.isEmpty {
            items.removeAll { $0.name == msisdnQueryKey }
            items.append(URLQueryItem(name: msisdnQueryKey, value: msisdn))
        }
        let token = userToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty {
            items.removeAll { $0.name == tokenQueryKey }
            items.append(URLQueryItem(name: tokenQueryKey, value: token))
        }
        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }
}
