import Foundation
import TCNClient

class BluetoothMonitor {

    private var bluetoothService: TCNBluetoothService!
    private var tck: TemporaryContactKey = ReportAuthorizationKey().initialTemporaryContactKey

    func runMonitoring() {
        guard bluetoothService == nil else {
            return
        }

        bluetoothService = TCNBluetoothService(tcnGenerator: { () -> Data in
            let deviceName = UIDevice.current.name
            let deviceNameHash = CryptoProvider.sha256(data: deviceName.data(using: .utf8)!)

            //let tcn = self.tck.temporaryContactNumber.bytes
            let tcn = deviceNameHash[0..<16]

            NSLog("Bluetooth service asked for TCN. Returning \(tcn.base64EncodedString()). Composed from device name '\(deviceName)' and corresponding hash \(deviceNameHash.base64EncodedString())")
            return tcn
        }, tcnFinder: { (data, distance) in
            NSLog("Data is here: \(data). Distance: \(distance ?? 0)")
        }, errorHandler: { (error) in
            NSLog("Bluetooth service error: \(error)")
        })

        bluetoothService.start()
    }

}
