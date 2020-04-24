import Foundation
import TCNClient

internal class BluetoothMonitor {

    private var bluetoothService: TCNBluetoothService!
    private var tck: TemporaryContactKey

    private var keyPair: PublicPrivateKeyPair
    private var rak: ReportAuthorizationKey

    private var tcn: TemporaryContactNumber

    init() {
        self.keyPair = BluetoothMonitor.getKeyPair()
        let rak = BluetoothMonitor.getRAK()
        self.rak = rak
        let tck = BluetoothMonitor.getSavedTCK() ?? BluetoothMonitor.getInitialTCK(rak: rak)
        self.tck = tck
        self.tcn = tck.temporaryContactNumber

    }

    func runMonitoring() {
        guard bluetoothService == nil else {
            return
        }

        bluetoothService = TCNBluetoothService(tcnGenerator: { () -> Data in
            let tcn = self.tcn.bytes
            Log.info("Someone over Bluetooth asked for TCN. Returning \(tcn.base64EncodedString()).")
            return tcn
        }, tcnFinder: { (tcn, distance) in
            Log.debug("Discovered new TCN: \(tcn.base64EncodedString()). Distance: \(distance ?? 0). Saving it to contacts DB...")
            PersistentStorage.appendValue(tcn, toArrayForKey: "encounteredTCNs")
        }, errorHandler: { (error) in
            Log.error("Bluetooth service error: \(error)")
        })

        bluetoothService.start()

        Log.debug("Started Bluetooth monitoring. Initial TCN is: \(tcn.bytes.base64EncodedString())")

        startTCNUpdating()
    }

    func startTCNUpdating() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { (timer) in
            self.tck = self.tck.ratchet()!
            self.tcn = self.tck.temporaryContactNumber

            PersistentStorage.setValue(self.tck.bytes, forKey: "tckBytes")
            PersistentStorage.setValue(self.tck.index, forKey: "tckIndex")

            Log.debug("Rotating TCN. New TCN is: \(self.tcn.bytes.base64EncodedString())")
        }
    }

    func generateReport() -> TCNClient.Report {
        let reportVerificationPublicKeyBytes = keyPair.publicKey
        let temporaryContactKeyBytes = tck.bytes
        let startIndex = UInt16(1)
        let endIndex = tck.index
        let memoType = MemoType.CovidWatchV1
        let memoData = Data([1])

        return Report(reportVerificationPublicKeyBytes: reportVerificationPublicKeyBytes, temporaryContactKeyBytes: temporaryContactKeyBytes, startIndex: startIndex, endIndex: endIndex, memoType: memoType, memoData: memoData)
    }

    static func getInitialTCK(rak: ReportAuthorizationKey) -> TemporaryContactKey {
        let tck = rak.initialTemporaryContactKey
        PersistentStorage.setValue(tck.bytes, forKey: "tckBytes")
        PersistentStorage.setValue(tck.index, forKey: "tckIndex")
        return tck
    }

    static func getSavedTCK() -> TemporaryContactKey? {
        if let tckBytes = PersistentStorage.getValue(forKey: "tckBytes") as? Data,
           let tckIndex = PersistentStorage.getValue(forKey: "tckIndex") as? Int,
           let rvkBytes = PersistentStorage.getValue(forKey: "publicKey") as? Data {
            return TemporaryContactKey(
                index: UInt16(tckIndex),
                reportVerificationPublicKeyBytes: rvkBytes,
                bytes: tckBytes)
        }

        return nil
    }

    static func getRAK() -> ReportAuthorizationKey {
        return ReportAuthorizationKey(keyPair: getKeyPair())
    }

    static func getKeyPair() -> PublicPrivateKeyPair {
        if let privateKey = PersistentStorage.getValue(forKey: "privateKey") as? Data,
            let publicKey = PersistentStorage.getValue(forKey: "publicKey") as? Data {
            return SavedKeyPair(privateKey: privateKey, publicKey: publicKey)
        } else {
            let keyPair = CryptoProvider.generateKeyPair()
            PersistentStorage.setValue(keyPair.privateKey, forKey: "privateKey")
            PersistentStorage.setValue(keyPair.publicKey, forKey: "publicKey")

            return keyPair
        }
    }

}

public struct SavedKeyPair: PublicPrivateKeyPair {

    public let privateKey: Data
    public let publicKey: Data

    public init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }

    public func signature<D>(for data: D) throws -> Data where D : DataProtocol {
        // tmp, do nothing
        return Data()
    }

}
