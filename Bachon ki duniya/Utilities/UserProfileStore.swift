import Foundation

struct UserProfileAPIResponse: Decodable {
    let status: String
    let code: String
    let data: UserProfile
    /// Top-level flag from `GET /profile/{msisdn}` — `false` means session is expired.
    let tokenValidation: Bool?

    enum CodingKeys: String, CodingKey {
        case status, code, data
        case tokenValidation = "token_validation"
    }

    /// Prefer top-level `token_validation`, then nested `data.token_validation`.
    /// Missing flag is treated as valid (older responses).
    var isTokenValid: Bool {
        if let tokenValidation { return tokenValidation }
        if let nested = data.tokenValidation { return nested }
        return true
    }
}

/// Remote profile from `GET /profile/{msisdn}`.
struct UserProfile: Codable, Equatable {
    let userid: Int
    let msisdn: Int64
    let name: String?
    let image: String?
    let planId: Int?
    let isSubscribed: Int?
    let tokenValidation: Bool?
    let rechargeDate: String?
    let extraDate: String?
    let needsResubscribe: Bool?

    enum CodingKeys: String, CodingKey {
        case userid, msisdn, name, image
        case planId = "plan_id"
        case isSubscribed = "is_subscribed"
        case tokenValidation = "token_validation"
        case rechargeDate = "recharge_date"
        case extraDate = "extra_date"
        case needsResubscribe = "needs_resubscribe"
    }

    var displayName: String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var imageURL: URL? {
        guard let image, !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return URL(string: image)
    }

    var isSubscribedBool: Bool { (isSubscribed ?? 0) != 0 }
}

extension Notification.Name {
    static let userProfileDidChange = Notification.Name("UserProfileDidChange")
}

/// Persisted profile for use anywhere in the app.
enum UserProfileStore {

    private static let storageKey = "cached_user_profile_v1"
    private static let lock = NSLock()
    private static var memoryCache: UserProfile?

    static var current: UserProfile? {
        lock.lock()
        defer { lock.unlock() }
        if let memoryCache { return memoryCache }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        memoryCache = decoded
        return decoded
    }

    static func save(_ profile: UserProfile) {
        lock.lock()
        memoryCache = profile
        lock.unlock()
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let name = profile.displayName {
            UserSession.saveDisplayName(name)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userProfileDidChange, object: profile)
        }
    }

    static func clear() {
        lock.lock()
        memoryCache = nil
        lock.unlock()
        UserDefaults.standard.removeObject(forKey: storageKey)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userProfileDidChange, object: nil)
        }
    }
}

/// Fetches `/profile/{msisdn}` in the background and caches the result.
/// Also enforces session validity via `token_validation`.
enum UserProfileSync {

    private static let validationLock = NSLock()
    private static var isValidatingSession = false

    /// Fire-and-forget refresh when an MSISDN is available (app launch, login, foreground).
    static func refreshInBackground() {
        guard UserDefaults.standard.bool(forKey: AppDefaultsKeys.isLoggedIn)
                || UserSession.sessionToken != nil else { return }
        guard let msisdn = UserSession.msisdnDigits else { return }
        fetchAndEnforceSession(msisdn: msisdn, saveProfileIfValid: true)
    }

    /// Instant check when a video URL is empty/broken — session may have expired.
    static func validateSessionAfterBrokenMedia() {
        guard UserDefaults.standard.bool(forKey: AppDefaultsKeys.isLoggedIn)
                || UserSession.sessionToken != nil else { return }

        guard let msisdn = UserSession.msisdnDigits else {
            // Logged-in state without MSISDN/token context — force session-out UX.
            SessionExpiredPresenter.presentIfNeeded()
            return
        }
        fetchAndEnforceSession(msisdn: msisdn, saveProfileIfValid: false)
    }

    private static func fetchAndEnforceSession(msisdn: String, saveProfileIfValid: Bool) {
        validationLock.lock()
        if isValidatingSession {
            validationLock.unlock()
            return
        }
        isValidatingSession = true
        validationLock.unlock()

        APIManager.shared.fetchProfile(msisdn: msisdn) { result in
            defer {
                validationLock.lock()
                isValidatingSession = false
                validationLock.unlock()
            }

            switch result {
            case .success(let response):
                if !response.isTokenValid {
                    // Clears saved OTP `session_token` and shows session-out popup.
                    SessionExpiredPresenter.presentIfNeeded()
                    return
                }
                if saveProfileIfValid {
                    UserProfileStore.save(response.data)
                }
            case .failure(let error):
                print("UserProfileSync: \(error.localizedDescription)")
            }
        }
    }
}
