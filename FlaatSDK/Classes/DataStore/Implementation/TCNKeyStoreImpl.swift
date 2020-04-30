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

        return newTCK
    }

    func fetchCurrentRAK() throws -> ReportAuthorizationKey? {
        // TBD
        return nil
    }

    func fetchCurrentTCK() throws -> TemporaryContactKey? {
        // TBD
        return nil
    }

    func saveNewTCK(_ tck: TemporaryContactKey) throws {
        // TBD
    }

}
