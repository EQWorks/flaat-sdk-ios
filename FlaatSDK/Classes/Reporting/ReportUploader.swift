import Foundation
import TCNClient

class ReportUploader: NSObject {

    private let geoHashPrecision = 6
    private let flaatAPI: FlaatAPIServer

    init(flaatAPI: FlaatAPIServer) {
        self.flaatAPI = flaatAPI
    }

    func uploadReport(days: Int = 21, tcnReport: TCNClient.SignedReport, validationPin: String, completion: @escaping (Error?) -> Void) {
        Log.info("Uploading report...")

        let locationReader = PrivateKitLocationReader()
        let allRecords = locationReader.readAllLoggedLocations()
        let eligibleRecords = self.takeLast(days: days, locationRecords: allRecords)
        let reportedLocations = self.mergeLocationRecords(eligibleRecords)

        Log.debug("Locations in report:\n\(reportedLocations)")

        let report = TCNReport(validationPin: validationPin, traces: reportedLocations, tcnData: try! tcnReport.serializedData())

        flaatAPI.uploadTCNReport(report) { (result) in
            let completionError: Error?
            switch result {
            case .failure(let error):
                Log.error("Failed to upload report: \(error)")
                completionError = error
            case .success:
                Log.info("Successfully uploaded report")
                completionError = nil
            }

            DispatchQueue.main.async {
                completion(completionError)
            }
        }
    }

    private func takeLast(days: Int, locationRecords: [GeoLocationRecord]) -> [GeoLocationRecord] {
        let cutOffDate = Date().addingTimeInterval(TimeInterval(-days * 24 * 60 * 60))
        if let startIndex = locationRecords.firstIndex(where: { $0.timestamp > cutOffDate }) {
            return Array(locationRecords.suffix(from: startIndex))
        } else {
            return []
        }
    }

    private func mergeLocationRecords(_ locationRecords: [GeoLocationRecord]) -> [ReportedLocation] {
        guard !locationRecords.isEmpty else { return [] }

        var reportedLocations: [ReportedLocation] = [locationRecords.first!.reportedLocation(hashPresision: geoHashPrecision)]

        for locationRecord in locationRecords {
            let geoHash = locationRecord.location.geoHash(precision: geoHashPrecision)
            let last = reportedLocations.last!

            if last.geoHash != geoHash {
                let startTime = Int64(locationRecord.timestamp.timeIntervalSince1970)
                reportedLocations[reportedLocations.count - 1] =
                        ReportedLocation(geoHash: last.geoHash, startTime: last.startTime, endTime: startTime)
                reportedLocations.append(ReportedLocation(geoHash: geoHash, startTime: startTime, endTime: startTime))
            }
        }

        return reportedLocations
    }

}

extension GeoLocationRecord {

    func reportedLocation(hashPresision: Int) -> ReportedLocation {
        let geoHash = location.geoHash(precision: hashPresision)
        let startTime = Int64(timestamp.timeIntervalSince1970)
        return ReportedLocation(geoHash: geoHash, startTime: startTime, endTime: startTime)
    }
}

