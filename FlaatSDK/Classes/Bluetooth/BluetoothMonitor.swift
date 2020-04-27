import Foundation
import TCNClient

internal class BluetoothMonitor {

    private var bluetoothService: TCNBluetoothService!

    private let rak: ReportAuthorizationKey

    private var tck: TemporaryContactKey
    private var tcn: TemporaryContactNumber

    init() {
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
//        }, tcnFinder: { (tcn, distance) in
//            Log.debug("Discovered new TCN: \(tcn.base64EncodedString()). Distance: \(distance ?? 0). Saving it to contacts DB...")
//            PersistentStorage.appendValue(tcn, toArrayForKey: "encounteredTCNs")
        }, tcnFinder: { (tcn) in
            Log.debug("Discovered new TCN: \(tcn.base64EncodedString()). Saving it to contacts DB...")
            PersistentStorage.appendValue(tcn, toArrayForKey: "encounteredTCNs")
        }, errorHandler: { (error) in
            Log.error("Bluetooth service error: \(error)")
        })

        bluetoothService.start()

        Log.debug("Started Bluetooth monitoring. Initial TCN is: \(tcn.bytes.base64EncodedString())")

        startTCNUpdating()
    }

    func startTCNUpdating() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { (timer) in
            self.tck = self.tck.ratchet()!
            self.tcn = self.tck.temporaryContactNumber

            PersistentStorage.setValue(self.tck.bytes, forKey: "tckBytes")
            PersistentStorage.setValue(self.tck.index, forKey: "tckIndex")

            Log.debug("Rotating TCN. New TCN is: \(self.tcn.bytes.base64EncodedString())")
        }
    }

    func generateReport() throws -> TCNClient.SignedReport {
        let startIndex = UInt16(1)
        let endIndex = tck.index
        let memoType = MemoType.CovidWatchV1
        let memoData = Data([1])

        return try rak.createSignedReport(memoType: memoType, memoData: memoData, startIndex: startIndex, endIndex: endIndex)
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
        if let privateKey = PersistentStorage.getValue(forKey: "privateKey") as? Data,
           let rak = try? ReportAuthorizationKey(serializedData: privateKey) {
            return rak
        } else {
            let rak = ReportAuthorizationKey()
            PersistentStorage.setValue(rak.serializedData(), forKey: "privateKey")
            PersistentStorage.setValue(rak.initialTemporaryContactKey.reportVerificationPublicKeyBytes, forKey: "publicKey")
            return rak
        }
    }

}

public struct SavedKeyPair: AsymmetricKeyPair {

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
