import Foundation
import TCNClient

class KeychainKeyStore: SecureKeyStore {

    private let account = "flaat-tcn-rak"

    func saveRAK(_ rak: ReportAuthorizationKey) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData: rak.serializedData()
            ] as [String: Any]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw TCNKeyStoreError.keychainSaveFailed(status)
        }
    }

    func fetchRAK() throws -> ReportAuthorizationKey? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecReturnData: true
            ] as [String: Any]

        var item: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &item) {
            case errSecSuccess:
                guard let data = item as? Data else { return nil }
                return try ReportAuthorizationKey(serializedData: data)
            case errSecItemNotFound:
                return nil
            case let status:
                throw TCNKeyStoreError.keychainSaveFailed(status)
        }
    }

    func eraseRAK() throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ] as [String: Any]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            throw TCNKeyStoreError.keychainSaveFailed(status)
        }
    }
}
