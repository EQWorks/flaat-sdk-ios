import Foundation
import CoreData
import TCNClient

extension IncomingTCNReportImpl: IncomingTCNReport {

    @nonobjc class func fetchRequest() -> NSFetchRequest<IncomingTCNReportImpl> {
        return NSFetchRequest<IncomingTCNReportImpl>(entityName: "IncomingTCNReport")
    }

    @NSManaged var reportData: Data
    @NSManaged var dateReceived: Date
    @NSManaged var processed: Bool
    @NSManaged var tcnEncounters: NSSet?

    var tcnReport: TCNClient.Report {
        return try! TCNClient.Report(serializedData: reportData)
    }
}

// MARK: Generated accessors for tcnEncounters
extension IncomingTCNReportImpl {

    @objc(addTcnEncountersObject:)
    @NSManaged func addToTcnEncounters(_ value: TCNEncounterImpl)

    @objc(removeTcnEncountersObject:)
    @NSManaged func removeFromTcnEncounters(_ value: TCNEncounterImpl)

    @objc(addTcnEncounters:)
    @NSManaged func addToTcnEncounters(_ values: NSSet)

    @objc(removeTcnEncounters:)
    @NSManaged func removeFromTcnEncounters(_ values: NSSet)

}
