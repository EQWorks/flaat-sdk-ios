import Foundation
import TCNClient

internal class ReportAnalyzer {

    func downloadAndAnalyzeReports(completion: @escaping (_ infected: Bool) -> Void) {
        FlaatAPI.default.downloadReports(locations: []) { (result) in
            switch result {
            case .failure(let error):
                Log.error("Failed to download reports: \(error)")
                completion(false)
            case .success(let serializedReports):
                self.saveReports(serializedReports)
                let infected = self.analyzeReports(serializedReports)
                completion(infected)
                Log.info("Successfully downloaded \(serializedReports.count) reports")
            }
        }
    }

    private func analyzeReports(_ serializedReports: [Data]) -> Bool {
        let encounteredTCNs = Set(PersistentStorage.getValue(forKey: "encounteredTCNs") as? [Data] ?? [])

        for reportData in serializedReports.reversed() {
            guard let report = try? TCNClient.SignedReport(serializedData: reportData) else {
                Log.error("Cannot deserialize report \(reportData.base64EncodedString())")
                continue
            }

            let reportTCNs = Set(report.report.getTemporaryContactNumbers().map { $0.bytes } )
            let intersectedTCNs = reportTCNs.intersection(encounteredTCNs)
            if !intersectedTCNs.isEmpty {
                Log.info("Discovered intersecting TCNs! List: \(intersectedTCNs.map {$0.base64EncodedString()} )")
                return true
            }
        }

        return false
    }

    private func saveReports(_ serializedReports: [Data]) {
        // TODO: implement
    }

    private func getLocations() -> [GeoLocation] {
        // TODO: read locations from PrivateKit logs
        return []
    }

}
