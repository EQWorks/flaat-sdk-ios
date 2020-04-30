import Foundation
import TCNClient

class UserDefaultsStore: UnsecureKeyStore {

    func saveNewTCK(_ tck: TemporaryContactKey) throws {
        // TBD
    }

    func fetchCurrentTCK() throws -> TemporaryContactKey? {
        // TBD
        return nil
    }

    func deleteCurrentTCK() throws {
        // TBD
    }
}
