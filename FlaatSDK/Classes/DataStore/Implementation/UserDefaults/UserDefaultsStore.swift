import Foundation
import TCNClient

class UserDefaultsStore: UnsecureKeyStore {

    private let tckKey = "Flaat-CurrentTCK"

    func saveNewTCK(_ tck: TemporaryContactKey) throws {
        UserDefaults.standard.set(tck.asDict(), forKey: tckKey)
    }

    func fetchCurrentTCK() throws -> TemporaryContactKey? {
        guard let dict = UserDefaults.standard.dictionary(forKey: tckKey) else {
            return nil
        }

        return try TemporaryContactKey.fromDict(dict)
    }

    func deleteCurrentTCK() throws {
        UserDefaults.standard.removeObject(forKey: tckKey)
    }
}

private extension TemporaryContactKey {

    func asDict() -> [String: Any] {
        return [
            "bytes": self.bytes,
            "index": self.index,
            "rvk": self.reportVerificationPublicKeyBytes
        ]
    }

    static func fromDict(_ dict: [String: Any]) throws -> TemporaryContactKey {
        guard let bytes = dict["bytes"] as? Data,
              let rvkBytes = dict["rvk"] as? Data,
              let index = dict["index"] as? UInt16 else {
            throw TCNKeyStoreError.dataInconsistency
        }

        return TemporaryContactKey(index: index, reportVerificationPublicKeyBytes: rvkBytes, bytes: bytes)
    }
}
