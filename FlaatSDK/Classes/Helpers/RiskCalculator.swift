import Foundation

class RiskCalculator {

    class func calculateRiskLevel(reports: [IncomingTCNReport]) -> RiskLevel {
        // TODO: implement proper risk calculation
        return reports.isEmpty ? 0.0 : 1.0
    }

    class func calculateRiskLevel(encounter: TCNEncounter) -> RiskLevel {
        // TODO: implement proper risk calculation
        return encounter.linkedReport == nil ? 0.0 : 1.0
    }

    class func convertReportsToExposures(_ reports: [IncomingTCNReport]) throws -> [ExposureDetails] {
        let exposureTCNEncounters = reports.flatMap { $0.linkedEncounters }
        return exposureTCNEncounters.map { encounter in
            let duration = encounter.lastTime.timeIntervalSince(encounter.firstTime)
            let riskLevel = calculateRiskLevel(encounter: encounter)
            return ExposureDetails(date: encounter.firstTime, duration: duration, riskLevel: riskLevel)
        }
    }
}
