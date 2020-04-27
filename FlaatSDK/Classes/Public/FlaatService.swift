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
        do {
            let tcnReport = try bluetoothMonitor.generateReport()
            reportUploader.uploadReport(days: days, tcnReport: tcnReport, validationPin: validationPin, completion: completion)
        } catch {
            completion(error)
            return
        }
    }

    public class func downloadAndAnalyzeReports(completion: @escaping (_ infected: Bool) -> Void) {
        let reportAnalyzer = ReportAnalyzer()
        reportAnalyzer.downloadAndAnalyzeReports(completion: completion)
    }
}
