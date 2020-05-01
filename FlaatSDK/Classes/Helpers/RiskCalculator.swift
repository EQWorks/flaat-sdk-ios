import Foundation

class RiskCalculator {

    class func calculateRiskLevel(reports: [IncomingTCNReport]) -> RiskLevel {
        // TODO: implement proper risk calculation
        return reports.isEmpty ? 0.0 : 1.0
    }
}
