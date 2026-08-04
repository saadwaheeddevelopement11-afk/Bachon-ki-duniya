import Foundation

// MARK: - Responses

struct ParentalMessageResponse: Decodable {
    let status: String
    let code: String
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success" || code == "000"
    }
}

struct ParentalStatusAPIResponse: Decodable {
    let status: String
    let code: String
    let data: ParentalStatusData?
}

struct ParentalStatusData: Codable, Equatable {
    let isEnabled: Bool
    let dailyLimitMinutes: Int
    let minutesUsedToday: Int
    let limitReached: Bool
    let lockedCategoryIds: [Int]

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case dailyLimitMinutes = "daily_limit_minutes"
        case minutesUsedToday = "minutes_used_today"
        case limitReached = "limit_reached"
        case lockedCategoryIds = "locked_category_ids"
    }
}

struct ParentalResetPINRequestResponse: Decodable {
    let status: String
    let code: String
    let message: String?
    let data: ParentalResetPINData?

    var isSuccess: Bool {
        status.lowercased() == "success" || code == "000"
    }
}

struct ParentalResetPINData: Decodable {
    let phone: String?
    let expiresIn: String?

    enum CodingKeys: String, CodingKey {
        case phone
        case expiresIn = "expires_in"
    }
}

extension Notification.Name {
    static let parentalStatusDidChange = Notification.Name("ParentalStatusDidChange")
}

// MARK: - Store

enum ParentalStatusStore {

    private static let storageKey = "parental_status_v1"
    private static let lock = NSLock()
    private static var memory: ParentalStatusData?

    static var current: ParentalStatusData? {
        lock.lock()
        defer { lock.unlock() }
        if let memory { return memory }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(ParentalStatusData.self, from: data) else {
            return nil
        }
        memory = decoded
        return decoded
    }

    static func isCategoryLocked(_ categoryId: Int) -> Bool {
        guard let status = current, status.isEnabled else { return false }
        return status.lockedCategoryIds.contains(categoryId)
    }

    static func save(_ status: ParentalStatusData) {
        lock.lock()
        memory = status
        lock.unlock()
        if let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .parentalStatusDidChange, object: status)
        }
    }

    static func clear() {
        lock.lock()
        memory = nil
        lock.unlock()
        UserDefaults.standard.removeObject(forKey: storageKey)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .parentalStatusDidChange, object: nil)
        }
    }

    /// Background refresh used on launch / home appear.
    static func refreshInBackground(completion: ((Result<ParentalStatusData, Error>) -> Void)? = nil) {
        guard let msisdn = UserSession.msisdnDigits else {
            completion?(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No MSISDN"])))
            return
        }
        APIManager.shared.fetchParentalStatus(msisdn: msisdn) { result in
            switch result {
            case .success(let status):
                save(status)
                completion?(.success(status))
            case .failure(let error):
                print("ParentalStatusStore: \(error.localizedDescription)")
                completion?(.failure(error))
            }
        }
    }
}
