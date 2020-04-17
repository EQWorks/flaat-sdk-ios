import Foundation

struct TCNReport {

    let validationPin: String
    let traces: [ReportedLocation]
    let tcnData: Data

    func json() -> JSONObject {
        return [
            "validationPin": validationPin,
            "traces": traces.map { $0.json() },
            "tcnData": tcnData.base64EncodedString()
        ]
    }
}

struct ReportedLocation {

    let geoHash: String
    let startTime: Int64
    let endTime: Int64

    func json() -> JSONObject {
        return ["geohash": geoHash, "start": startTime, "end": endTime]
    }
}

extension ReportedLocation: CustomStringConvertible {

    var description: String {
        return "(geohash: \(geoHash), start: \(startTime), end: \(endTime)"
    }
}
