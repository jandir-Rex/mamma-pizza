import Foundation
import Security

enum KeychainStore {
    private static let service = Bundle.main.bundleIdentifier ?? "mamma.pizza"

    private static func base(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    static func set(_ value: String, for key: String) {
        SecItemDelete(base(key) as CFDictionary)
        var q = base(key)
        q[kSecValueData as String] = Data(value.utf8)
        // ThisDeviceOnly: el token NUNCA sale del dispositivo (no viaja por iCloud Keychain).
        // Recomendado por Apple para tokens de autenticación.
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        var q = base(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(_ key: String) {
        SecItemDelete(base(key) as CFDictionary)
    }
}
