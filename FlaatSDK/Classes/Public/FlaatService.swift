import Foundation

public class FlaatService {

    private static var bluetoothMonitor = BluetoothMonitor()

    public class func launch(apiKey: String, logLevel: LogLevel = .info) {
        FlaatAPI.apiKey = apiKey
        Log.logLevel = logLevel

        bluetoothMonitor.runMonitoring()
    }

    public class func uploadReport(days: Int = 21, validationPin: String, completion: @escaping (Error?) -> Void) {
        let reportUploader = ReportUploader()
        let tcnReport = bluetoothMonitor.generateReport()
        reportUploader.uploadReport(days: days, tcnReport: tcnReport, validationPin: validationPin, completion: completion)
    }

}
