import Foundation
import TCNClient

protocol KeyStore {

    func resetTCNKeys() throws -> TemporaryContactKey
    func fetchCurrentRAK() throws -> ReportAuthorizationKey?
    func fetchCurrentTCK() throws -> TemporaryContactKey?
    func saveNewTCK(_ tck: TemporaryContactKey) throws
}

protocol SecureKeyStore {

    func saveRAK(_ rak: ReportAuthorizationKey)
    func fetchRAK() throws -> ReportAuthorizationKey?
    func eraseRAK() throws
}

protocol UnsecureKeyStore {

    func saveNewTCK(_ tck: TemporaryContactKey) throws
    func fetchCurrentTCK() throws -> TemporaryContactKey?
    func deleteCurrentTCK() throws
}
