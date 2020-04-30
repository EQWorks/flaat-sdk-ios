import Foundation

public class FlaatService {

    private static var bluetoothMonitor: BluetoothMonitor!
    private static var dataStore: TCNDataStore!
    private static var keyStore: KeyStore!

    public class func launch(apiKey: String, logLevel: LogLevel = .info) throws {
        FlaatAPI.apiKey = apiKey
        Log.logLevel = logLevel

        dataStore = try TCNDataStoreCoreData()
        bluetoothMonitor = BluetoothMonitor(dataStore: dataStore, keyStore: keyStore)
        bluetoothMonitor.runMonitoring()
    }

    public class func uploadReport(days: Int = 21, validationPin: String, completion: @escaping (Error?) -> Void) {
        let reportUploader = ReportUploader()
        do {
            let tcnReport = try bluetoothMonitor.generateReport()
            let savedReport = try dataStore.saveOutgoingReport(tcnReport, dateCreated: Date())
            reportUploader.uploadReport(days: days, tcnReport: tcnReport, validationPin: validationPin, completion: { error in
                if error != nil {
                    do {
                        try dataStore.markReportSubmitted(savedReport, onDate: Date())
                    } catch {
                        Log.error("Cannot mark report submitted in the data store")
                    }
                }
                completion(error)
            })
        } catch {
            completion(error)
            return
        }
    }

    public class func downloadAndAnalyzeReports(completion: @escaping (_ infected: Bool) -> Void) {
        let reportAnalyzer = ReportAnalyzer(dataStore: dataStore)
        reportAnalyzer.downloadAndAnalyzeReports(completion: completion)
    }
}
