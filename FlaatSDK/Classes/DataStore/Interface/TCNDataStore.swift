import Foundation
import TCNClient

protocol TCNEncounter {

    var tcn: TemporaryContactNumber { get }
    var firstTime: Date { get }
    var lastTime: Date { get }
    var closestRSSI: Double { get }
    var linkedReport: IncomingTCNReport? { get }
}

protocol IncomingTCNReport {

    var tcnReport: TCNClient.Report { get }
    var dateReceived: Date { get }
    var processed: Bool { get }
}

protocol OutgoingTCNReport {

    var signedReport: TCNClient.SignedReport { get }
    var dateCreated: Date { get }
    var dateSubmitted: Date? { get }
}

protocol TCNDataStore {

    func saveEncounteredTCN(_ tcn: TemporaryContactNumber, timestamp: Date, rssi: Double) throws
    func loadTCNEncounters(fromDate: Date?) throws -> [TCNEncounter]
    func cleanupOldEncounters(untilDate: Date) throws

    func saveOutgoingReport(_ report: OutgoingTCNReport) throws
    func fetchOutgoingReports(onlyNotSent: Bool) throws -> [OutgoingTCNReport]

    func saveIncomingReport(_ report: IncomingTCNReport) throws
    func fetchIncomingReports(onlyUnprocessed: Bool) throws -> [IncomingTCNReport]
    func deleteIncomingReports(_ reports: [IncomingTCNReport]) throws

    func linkEncounter(_ encounter: TCNEncounter, toReport report: IncomingTCNReport) throws
}
