//
//  AppAnalytics.swift
//  Bachon ki duniya
//

import Foundation
import UIKit
import FirebaseAnalytics

enum AppAnalytics {

    /// Names registered in Firebase Console → Analytics → Custom definitions.
    enum CustomKey {
        static let msisdn = "msisdn"
        static let query = "query"
        static let device = "device"
    }

    // MARK: - Session / user props

    /// Call once at launch (and after login). Sets `msisdn` + `device` user properties.
    static func configureUserProperties(msisdn: String? = UserSession.msisdnDigits) {
        setUserProperty(deviceDescription(), forName: CustomKey.device)
        if let msisdn, !msisdn.isEmpty {
            setUserId(msisdn)
            setUserProperty(msisdn, forName: CustomKey.msisdn)
        }
    }

    static func clearUser() {
        setUserId(nil)
        setUserProperty(nil, forName: CustomKey.msisdn)
    }

    static func deviceDescription() -> String {
        let model = UIDevice.current.model // e.g. "iPhone"
        let name = UIDevice.current.name
        let system = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        // User properties max ~36 chars recommended; keep compact.
        let raw = "\(model)|\(system)"
        return String(raw.prefix(36))
    }

    // MARK: - Screen / session

    static func logScreen(_ name: String, className: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: enriched([
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: className ?? name
        ]))
    }

    // MARK: - Auth

    static func logLogin(method: String = "otp") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: enriched([
            AnalyticsParameterMethod: method
        ]))
    }

    static func logLogout() {
        Analytics.logEvent("logout", parameters: enriched(nil))
    }

    // MARK: - Content

    static func logSelectContent(type: String, id: String, name: String? = nil) {
        var params: [String: Any] = [
            AnalyticsParameterContentType: type,
            AnalyticsParameterItemID: id
        ]
        if let name, !name.isEmpty {
            params[AnalyticsParameterItemName] = name
        }
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: enriched(params))
    }

    static func logPlayVideo(id: String, title: String, category: String? = nil) {
        var params: [String: Any] = [
            "video_id": id,
            "video_title": title
        ]
        if let category, !category.isEmpty {
            params["category"] = category
        }
        Analytics.logEvent("play_video", parameters: enriched(params))
    }

    static func logOpenGame(title: String, url: String? = nil) {
        var params: [String: Any] = ["game_title": title]
        if let url, !url.isEmpty {
            params["game_url"] = String(url.prefix(100))
        }
        Analytics.logEvent("open_game", parameters: enriched(params))
    }

    /// Logs search with custom parameter `query` (register as Custom dimension).
    static func logSearch(term: String) {
        let q = String(term.prefix(100))
        Analytics.logEvent(AnalyticsEventSearch, parameters: enriched([
            AnalyticsParameterSearchTerm: q,
            CustomKey.query: q
        ]))
    }

    static func logLanguageChange(code: String) {
        Analytics.logEvent("language_change", parameters: enriched([
            "language_code": code
        ]))
    }

    // MARK: - Parental / screen time

    static func logParentalAction(_ action: String) {
        Analytics.logEvent("parental_action", parameters: enriched([
            "action": action
        ]))
    }

    // MARK: - Generic

    static func log(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: enriched(parameters))
    }

    static func setUserId(_ id: String?) {
        Analytics.setUserID(id)
    }

    static func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    // MARK: - Private

    /// Attaches `msisdn` + `device` on every event so they can be Custom dimensions (Event scope).
    private static func enriched(_ parameters: [String: Any]?) -> [String: Any] {
        var params = parameters ?? [:]
        if let msisdn = UserSession.msisdnDigits, !msisdn.isEmpty {
            params[CustomKey.msisdn] = msisdn
        }
        params[CustomKey.device] = deviceDescription()
        return params
    }
}
