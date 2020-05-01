import Foundation
import TCNClient

class UserDefaultsStore: UnsecureKeyStore {

    private let tckKey = "Flaat-CurrentTCK"
    private static let lastReceivedReportDateKey = "Flaat-LastReceivedReportDate"

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

    static var lastReceivedReportDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: lastReceivedReportDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastReceivedReportDateKey)
        }
    }

    // TODO: add possibility to store risk assessment parameters
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
