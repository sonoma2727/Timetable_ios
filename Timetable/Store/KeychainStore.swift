import Foundation
import Security

struct Credentials: Equatable {
    let account: String
    let password: String
}

final class KeychainStore {

    private let service = "io.github.sonoma2727.timetable.credentials"
    private let keyAccount = "account"
    private let keyPassword = "password"
    private let keyRemember = "remember"

    func save(account: String, password: String, remember: Bool) {
        UserDefaults.standard.set(remember, forKey: keyRemember)
        if remember {
            write(key: keyAccount, value: account)
            write(key: keyPassword, value: password)
        } else {
            delete(key: keyAccount)
            delete(key: keyPassword)
        }
    }

    func current() -> Credentials? {
        guard UserDefaults.standard.bool(forKey: keyRemember) else { return nil }
        guard let account = read(key: keyAccount), !account.isEmpty,
              let password = read(key: keyPassword), !password.isEmpty else { return nil }
        return Credentials(account: account, password: password)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: keyRemember)
        delete(key: keyAccount)
        delete(key: keyPassword)
    }

    private func baseQuery(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    private func write(key: String, value: String) {
        var query = baseQuery(key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = Data(value.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
    }
}
