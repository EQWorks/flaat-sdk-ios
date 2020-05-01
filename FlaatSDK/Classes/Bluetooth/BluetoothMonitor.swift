import Foundation
import TCNClient

class BluetoothMonitor {

    private var bluetoothService: TCNBluetoothService!

    private let dataStore: TCNDataStore
    private let keyStore: TCNKeyStore
    private let tcnRotationInterval: TimeInterval

    private var tck: TemporaryContactKey
    private var tcn: TemporaryContactNumber

    init(dataStore: TCNDataStore, keyStore: TCNKeyStore, tcnRotationInterval: TimeInterval) throws {
        self.dataStore = dataStore
        self.keyStore = keyStore
        self.tcnRotationInterval = tcnRotationInterval

        let currentRAK = try? keyStore.fetchCurrentRAK()
        var currentTCK = try? keyStore.fetchCurrentTCK()

        if currentRAK == nil {
            // WARNING: All TCN keys may have to be reset only if there is no RAK saved previously or when there is an issue with readin RAK from keychain.
            //          Whenever RAK is reset there is no way for anyone to restore previously transmitted TCNs, so the information will be lost.
            currentTCK = try keyStore.resetTCNKeys()
        } else if currentTCK == nil {
            // This is an edge case that should not happen under normal circumstances. In this case we assume that we should start with initial TCK.
            currentTCK = currentRAK!.initialTemporaryContactKey
        }

        guard let tck = currentTCK else {
            throw TCNKeyStoreError.dataInconsistency
        }

        self.tck = tck
        self.tcn = tck.temporaryContactNumber
    }

    func runMonitoring() {
        guard bluetoothService == nil else {
            return
        }

        bluetoothService = TCNBluetoothService(tcnGenerator: { () -> Data in
            let tcn = self.tcn.bytes
            Log.info("Another device asked for TCN. Returning \(tcn.base64EncodedString()).")
            return tcn
        }, tcnFinder: { [weak self] (tcn, distance) in
            guard let self = self else { return }
            Log.debug("Discovered new TCN: \(tcn.base64EncodedString()). Distance: \(distance ?? 0). Saving it to contacts DB...")

            // TODO: temporarily send to main queue but needs to be fixed for saving in background queue
            DispatchQueue.main.async {
                do {
                    try self.dataStore.saveEncounteredTCN(TemporaryContactNumber(bytes: tcn), timestamp: Date(), distance: distance ?? 0)
                } catch {
                    Log.error("Cannot save TCN \(tcn.base64EncodedString())")
                    fatalError("Cannot save encountered TCN")
                }
            }
        }, errorHandler: { (error) in
            Log.error("Bluetooth service error: \(error)")
        })

        bluetoothService.start()

        Log.debug("Started Bluetooth monitoring. Initial TCN is: \(tcn.bytes.base64EncodedString())")

        startTCNRotation()
    }

    private func startTCNRotation() {
        Timer.scheduledTimer(withTimeInterval: tcnRotationInterval, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }

            self.tck = self.tck.ratchet()!
            self.tcn = self.tck.temporaryContactNumber
            do {
                try self.keyStore.saveNewTCK(self.tck)
            } catch {
                fatalError("Cannot save new TCK")
            }

            Log.debug("Rotating TCN. New TCN is: \(self.tcn.bytes.base64EncodedString())")
        }
    }

    func generateReport() throws -> TCNClient.SignedReport {
        let startIndex = UInt16(1)
        let endIndex = tck.index
        let memoType = MemoType.CovidWatchV1
        let memoData = Data([1])

        guard let rak = try keyStore.fetchCurrentRAK() else {
            throw TCNKeyStoreError.dataInconsistency
        }

        return try rak.createSignedReport(memoType: memoType, memoData: memoData, startIndex: startIndex, endIndex: endIndex)
    }
}
