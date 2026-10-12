//
//  MSISDNTokenEncryptor.swift
//  Bachon ki duniya
//
//  Shared contract with KIDO web: AES-256-GCM token for /ios/subscribe and /ios/delete-account.
//

import CryptoKit
import Foundation

enum MSISDNTokenEncryptor {
    /// 32-byte AES key (standard base64). Do not log this value.
    private static let aesKeyBase64 = "CbNCHeDvxw8Wyc4i4NRflhAZJHzAzSX7CYTgcSeQd8M="

    /// Default token lifetime matching web contract (15 minutes).
    static let defaultTTLSeconds: TimeInterval = 900

    /// Encrypts `{msisdn}:{expiry_unix}` → base64url(nonce ‖ ciphertext ‖ tag).
    static func encrypt(msisdn: String, ttlSeconds: TimeInterval = defaultTTLSeconds) -> String? {
        let digits = UserSession.normalizePhoneDigits(msisdn)
        guard UserSession.isValidPakistanMSISDN(digits) else { return nil }
        guard let keyData = Data(base64Encoded: aesKeyBase64), keyData.count == 32 else { return nil }

        let expiry = Int(Date().timeIntervalSince1970 + ttlSeconds)
        let plaintext = "\(digits):\(expiry)"
        guard let plaintextData = plaintext.data(using: .utf8) else { return nil }

        do {
            let key = SymmetricKey(data: keyData)
            let nonce = AES.GCM.Nonce()
            let sealed = try AES.GCM.seal(plaintextData, using: key, nonce: nonce)
            // CryptoKit combined form is nonce (12) ‖ ciphertext ‖ tag (16).
            guard let combined = sealed.combined else { return nil }
            return combined.base64URLEncodedString()
        } catch {
            return nil
        }
    }

    /// Encrypts the currently logged-in MSISDN, if available.
    static func encryptCurrentUser(ttlSeconds: TimeInterval = defaultTTLSeconds) -> String? {
        guard let msisdn = UserSession.msisdnDigits else { return nil }
        return encrypt(msisdn: msisdn, ttlSeconds: ttlSeconds)
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
