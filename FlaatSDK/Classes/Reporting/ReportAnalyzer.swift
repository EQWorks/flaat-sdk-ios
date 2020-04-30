import Foundation
import TCNClient

class ReportAnalyzer {

    private let dataStore: TCNDataStore

    init(dataStore: TCNDataStore) {
        self.dataStore = dataStore
    }

    func downloadAndAnalyzeReports(completion: @escaping (_ result: Result<Bool, Error>) -> Void) {
        FlaatAPI.default.downloadReports(locations: []) { (callResult) in
            switch callResult {
            case .failure(let error):
                Log.error("Failed to download reports: \(error)")
                completion(Result.failure(error))
            case .success(let serializedReports):
                Log.info("Successfully downloaded \(serializedReports.count) reports. Saving to persistent store.")
                let reports = self.convertDataToReports(serializedReports)

                do {
                    try self.saveReports(reports)
                } catch {
                    Log.error("Cannot save incoming TCN reports to persistent store: \(error)")
                }

                let result = Result { try self.analyzeReports() }
                completion(result)
            }
        }
    }

    private func analyzeReports() throws -> Bool {
        let encounteredTCNs = try dataStore.loadTCNEncounters(fromDate: Date().addingTimeInterval(-60.0*60*24*14))
        let encounteredTCNData = Set(encounteredTCNs.map { $0.tcn.bytes })

        let reportsToProcess = try dataStore.fetchIncomingReports(onlyUnprocessed: true)
        var reportsToDelete: [IncomingTCNReport] = []

        for report in reportsToProcess {
            let reportTCNs = Set( report.tcnReport.getTemporaryContactNumbers().map { $0.bytes } )
            let intersectedTCNs = reportTCNs.intersection(encounteredTCNData)

            // TODO: link reports with TCNs

            if !intersectedTCNs.isEmpty {
                Log.info("Discovered intersecting TCNs! List: \(intersectedTCNs.map {$0.base64EncodedString()} )")
                return true
            } else {
                reportsToDelete.append(report)
            }
        }

        try dataStore.deleteIncomingReports(reportsToDelete)

        return false
    }

    private func convertDataToReports(_ serializedReports: [Data]) -> [Report] {
        let reports = serializedReports.compactMap { reportData -> TCNClient.Report? in
            do {
                let report = try TCNClient.Report(serializedData: reportData)
                return report
            } catch {
                Log.error("Cannot deserialize report \(reportData.base64EncodedString()): \(error)")
                return nil
            }
        }

        return reports
    }

    private func saveReports(_ reports: [Report]) throws {
        try dataStore.saveIncomingReports(reports, dateReceived: Date())
    }

    private func getLocations() -> [GeoLocation] {
        // TODO: read locations from PrivateKit logs
        return []
    }

}
