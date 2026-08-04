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

    /// Optional display name if set later; otherwise profile shows the login phone.
    static var displayName: String? {
        let value = UserDefaults.standard.string(forKey: AppDefaultsKeys.displayName)
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Name if available, otherwise the logged-in phone number.
    static var profileDisplayText: String {
        if let name = UserProfileStore.current?.displayName { return name }
        if let displayName { return displayName }
        if let digits = msisdnDigits { return formattedPhone(digits) }
        return ""
    }

    static func saveDisplayName(_ name: String?) {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: AppDefaultsKeys.displayName)
        } else {
            UserDefaults.standard.set(trimmed, forKey: AppDefaultsKeys.displayName)
        }
    }

    /// Pakistan-style numbers: store with country code (e.g. `923…`), 10–15 digits.
    static func saveMsisdn(digits: String) {
        let normalized = normalizePhoneDigits(digits)
        guard isValidPakistanMSISDN(normalized) else { return }
        UserDefaults.standard.set(normalized, forKey: AppDefaultsKeys.msisdnDigits)
    }

    /// Always returns `92XXXXXXXXXX` (digits only, no `+` / spaces), regardless of input style:
    /// `+92 300…`, `92300…`, `0300…`, `300…`, `0092…`, etc.
    static func normalizePhoneDigits(_ raw: String) -> String {
        var digits = raw.filter(\.isNumber)

        // International dial-out prefix.
        while digits.hasPrefix("00") {
            digits = String(digits.dropFirst(2))
        }

        if digits.hasPrefix("92") {
            // Fix `9203…` → `923…`
            let national = String(digits.dropFirst(2))
            if national.hasPrefix("0") {
                digits = "92" + String(national.dropFirst())
            }
            return String(digits.prefix(15))
        }

        // Local formats: `03XXXXXXXXX` or `3XXXXXXXXX`
        if digits.hasPrefix("0") {
            digits = String(digits.dropFirst())
        }

        if !digits.hasPrefix("92") {
            digits = "92" + digits
        }

        return String(digits.prefix(15))
    }

    /// Valid API phone: starts with `92` and has 12–15 digits (e.g. `923001234567`).
    static func isValidPakistanMSISDN(_ digits: String) -> Bool {
        let normalized = normalizePhoneDigits(digits)
        guard normalized.hasPrefix("92") else { return false }
        return (12...15).contains(normalized.count)
    }

    static func formattedPhone(_ digits: String) -> String {
        let normalized = normalizePhoneDigits(digits)
        if normalized.hasPrefix("92") {
            return "+" + normalized
        }
        return normalized
    }

    static func clearMsisdn() {
        UserDefaults.standard.removeObject(forKey: AppDefaultsKeys.msisdnDigits)
        UserDefaults.standard.removeObject(forKey: AppDefaultsKeys.displayName)
        UserProfileStore.clear()
        ParentalStatusStore.clear()
    }
}
