import Foundation
import CoreData
import TCNClient

extension TCNEncounterImpl: TCNEncounter {

    @nonobjc class func fetchRequest() -> NSFetchRequest<TCNEncounterImpl> {
        return NSFetchRequest<TCNEncounterImpl>(entityName: "TCNEncounter")
    }

    @NSManaged var tcnBytes: Data
    @NSManaged var firstTime: Date
    @NSManaged var lastTime: Date
    @NSManaged var closestRSSI: Double
    @NSManaged var linkedReportImpl: IncomingTCNReportImpl?

    public var tcn: TemporaryContactNumber {
        return TemporaryContactNumber(bytes: tcnBytes)
    }

    var linkedReport: IncomingTCNReport? {
        return linkedReportImpl
    }
}
