import Foundation

struct UserProfileAPIResponse: Decodable {
    let status: String
    let code: String
    let data: UserProfile
}

/// Remote profile from `GET /profile/{msisdn}`.
struct UserProfile: Codable, Equatable {
    let userid: Int
    let msisdn: Int64
    let name: String?
    let image: String?
    let planId: Int?
    let isSubscribed: Int?

    enum CodingKeys: String, CodingKey {
        case userid, msisdn, name, image
        case planId = "plan_id"
        case isSubscribed = "is_subscribed"
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
enum UserProfileSync {

    /// Fire-and-forget refresh when an MSISDN is available (app launch, login, foreground).
    static func refreshInBackground() {
        guard let msisdn = UserSession.msisdnDigits else { return }
        APIManager.shared.fetchProfile(msisdn: msisdn) { result in
            switch result {
            case .success(let profile):
                UserProfileStore.save(profile)
            case .failure(let error):
                print("UserProfileSync: \(error.localizedDescription)")
            }
        }
    }
}
