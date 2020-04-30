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
            ] as CFDictionary

        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            throw TCNKeyStoreError.keychainSaveFailed(status)
        }
    }

    func fetchRAK() throws -> ReportAuthorizationKey? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecReturnData: true
            ] as CFDictionary

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        switch status {
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
            ] as CFDictionary

        let status = SecItemDelete(query)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw TCNKeyStoreError.keychainSaveFailed(status)
        }
    }
}
