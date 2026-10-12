//
//  SubscriptionsConfig.swift
//  Bachon ki duniya
//

import Foundation

/// Opens KIDO web handoff pages with an encrypted MSISDN token (`e=`).
enum SubscriptionsConfig {
    static let subscribeBaseURL = "https://kido.com.pk/ios/subscribe"
    static let deleteAccountBaseURL = "https://kido.com.pk/ios/delete-account"

    /// Optional plan id when opening subscribe for a specific package.
    static var planId: String?

    /// Suggested return deep link after successful subscribe (must match web allowlist).
    static let subscribeReturnURL = "kido://subscribe-success?status=ok"
    static let deleteAccountReturnURL = "kido://delete-account-done?status=ok"

    static func subscriptionURL(planId: String? = nil) -> URL? {
        handoffURL(
            base: subscribeBaseURL,
            planId: planId ?? self.planId,
            returnURL: subscribeReturnURL
        )
    }

    static func deleteAccountURL() -> URL? {
        handoffURL(
            base: deleteAccountBaseURL,
            planId: nil,
            returnURL: deleteAccountReturnURL
        )
    }

    private static func handoffURL(base: String, planId: String?, returnURL: String?) -> URL? {
        guard let token = MSISDNTokenEncryptor.encryptCurrentUser() else { return nil }
        guard var components = URLComponents(string: base) else { return nil }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "e", value: token)
        ]
        if let planId, !planId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "plan", value: planId))
        }
        if let returnURL, !returnURL.isEmpty {
            items.append(URLQueryItem(name: "return", value: returnURL))
        }
        components.queryItems = items
        return components.url
    }
}
