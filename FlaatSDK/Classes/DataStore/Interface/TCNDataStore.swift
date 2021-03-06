import Foundation
import TCNClient

protocol TCNEncounter {

    var tcn: TemporaryContactNumber { get }
    var firstTime: Date { get }
    var lastTime: Date { get }
    var closestDistance: Double { get }
    var linkedReport: IncomingTCNReport? { get }
}

protocol IncomingTCNReport {

    var tcnReport: TCNClient.Report { get }
    var dateReceived: Date { get }
    var processed: Bool { get }
    var linkedEncounters: [TCNEncounter] { get }
}

protocol OutgoingTCNReport {

    var signedReport: TCNClient.SignedReport { get }
    var dateCreated: Date { get }
    var dateSubmitted: Date? { get }
}

protocol TCNDataStore {

    func saveEncounteredTCN(_ tcn: TemporaryContactNumber, timestamp: Date, distance: Double) throws
    func loadTCNEncounters(fromDate: Date?) throws -> [TCNEncounter]
    func cleanupOldEncounters(untilDate: Date) throws

    @discardableResult
    func saveOutgoingReport(_ report: TCNClient.SignedReport, dateCreated: Date) throws -> OutgoingTCNReport
    func markReportSubmitted(_ report: OutgoingTCNReport, onDate date: Date) throws
    func fetchOutgoingReports(onlyNotSent: Bool) throws -> [OutgoingTCNReport]

    func saveIncomingReports(_ reports: [TCNClient.Report], dateReceived: Date) throws
    func fetchIncomingReports(processed: Bool) throws -> [IncomingTCNReport]
    func deleteIncomingReports(_ reports: [IncomingTCNReport]) throws

    func linkEncounters(_ encounters: [TCNEncounter], toReport report: IncomingTCNReport) throws
}

enum TCNDataError: Error {
    case initializationFailure
    case writeFailure
    case readFailure
    case invalidDataFormat
}
