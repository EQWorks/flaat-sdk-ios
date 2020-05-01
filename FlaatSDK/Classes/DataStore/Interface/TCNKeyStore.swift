import Foundation
import TCNClient

protocol TCNKeyStore {

    /// Deletes previously saved RAK and TCK, generates new keys, saves them in the corresponding key store and returns initial TCK.
    /// WARNING: Removing RAK from key store eliminates any possibility to restore TCNs derived from it and transmitted to other devices.
    /// This function should be called only on the first launch or after signed report generation when user wants to report infection case.
    func resetTCNKeys() throws -> TemporaryContactKey
    func fetchCurrentRAK() throws -> ReportAuthorizationKey?
    func fetchCurrentTCK() throws -> TemporaryContactKey?
    func saveNewTCK(_ tck: TemporaryContactKey) throws
}

protocol SecureKeyStore {

    func saveRAK(_ rak: ReportAuthorizationKey) throws
    func fetchRAK() throws -> ReportAuthorizationKey?
    func eraseRAK() throws
}

protocol UnsecureKeyStore {

    func saveNewTCK(_ tck: TemporaryContactKey) throws
    func fetchCurrentTCK() throws -> TemporaryContactKey?
    func deleteCurrentTCK() throws
}

enum TCNKeyStoreError: Error {
    case keychainSaveFailed(OSStatus)
    case keychainFetchFailed(OSStatus)
    case dataInconsistency
}

extension TCNKeyStoreError: CustomStringConvertible {

    var description: String {
        switch self {
        case .keychainFetchFailed:
            return "Failed to fetch item from keychain: \(statusMessage)"
        case .keychainSaveFailed:
            return "Failed to same item to keychain: \(statusMessage)"
        case .dataInconsistency:
            return "Inconsistent data in key store"
        }
    }

    private var status: OSStatus? {
        switch self {
        case .keychainFetchFailed(let status):
            return status
        case .keychainSaveFailed(let status):
            return status
        default:
            return nil
        }
    }

    private var statusMessage: String {
        guard let status = status else { return "" }
        return (SecCopyErrorMessageString(status, nil) as String?) ?? String(describing: status)
    }
}
