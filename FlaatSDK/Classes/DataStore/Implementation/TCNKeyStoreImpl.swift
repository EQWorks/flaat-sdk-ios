import Foundation
import TCNClient

class TCNKeyStoreImpl: TCNKeyStore {

    private let secureStore: SecureKeyStore
    private let unsecureKeyStore: UnsecureKeyStore

    init(secureStore: SecureKeyStore, unsecureKeyStore: UnsecureKeyStore) {
        self.secureStore = secureStore
        self.unsecureKeyStore = unsecureKeyStore
    }

    func resetTCNKeys() throws -> TemporaryContactKey {
        try secureStore.eraseRAK()
        try unsecureKeyStore.deleteCurrentTCK()

        let newRAK = ReportAuthorizationKey()
        try secureStore.saveRAK(newRAK)

        let newTCK = newRAK.initialTemporaryContactKey
        try unsecureKeyStore.saveNewTCK(newTCK)

        // TODO: consider saving TCK in secure key store as well (it won't be deleted upon app deletion from device)

        return newTCK
    }

    func fetchCurrentRAK() throws -> ReportAuthorizationKey? {
        return try secureStore.fetchRAK()
    }

    func fetchCurrentTCK() throws -> TemporaryContactKey? {
        return try unsecureKeyStore.fetchCurrentTCK()
    }

    func saveNewTCK(_ tck: TemporaryContactKey) throws {
        try unsecureKeyStore.saveNewTCK(tck)
    }
}
