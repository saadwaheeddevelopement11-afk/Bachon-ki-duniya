import Foundation

enum UserSession {

    static var hasMsisdn: Bool { msisdn != nil }

    static var msisdnDigits: String? {
        let value = UserDefaults.standard.string(forKey: AppDefaultsKeys.msisdnDigits)
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static var msisdn: Int64? {
        guard let digits = msisdnDigits else { return nil }
        return Int64(digits)
    }

    /// Pakistan-style numbers: store with country code (e.g. `923…`), 10–15 digits.
    static func saveMsisdn(digits: String) {
        let normalized = normalizePhoneDigits(digits)
        guard (10...15).contains(normalized.count) else { return }
        UserDefaults.standard.set(normalized, forKey: AppDefaultsKeys.msisdnDigits)
    }

    static func normalizePhoneDigits(_ raw: String) -> String {
        var digits = raw.filter(\.isNumber)
        if digits.hasPrefix("03"), digits.count == 11 {
            digits = "92" + String(digits.dropFirst())
        } else if digits.count == 10, digits.first == "3" {
            digits = "92" + digits
        }
        return String(digits.prefix(15))
    }

    static func clearMsisdn() {
        UserDefaults.standard.removeObject(forKey: AppDefaultsKeys.msisdnDigits)
    }
}
