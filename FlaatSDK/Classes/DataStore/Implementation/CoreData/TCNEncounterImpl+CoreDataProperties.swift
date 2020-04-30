import Foundation
import CoreData
import TCNClient

extension TCNEncounterImpl: TCNEncounter {

    @nonobjc class func fetchRequest() -> NSFetchRequest<TCNEncounterImpl> {
        return NSFetchRequest<TCNEncounterImpl>(entityName: "TCNEncounter")
    }

    @NSManaged var tcnBase64: String
    @NSManaged var firstTime: Date
    @NSManaged var lastTime: Date
    @NSManaged var closestDistance: Double
    @NSManaged var linkedReportImpl: IncomingTCNReportImpl?

    public var tcn: TemporaryContactNumber {
        return TemporaryContactNumber(bytes: tcnBytes)
    }

    var linkedReport: IncomingTCNReport? {
        return linkedReportImpl
    }

    var tcnBytes: Data {
        return Data(base64Encoded: tcnBase64)!
    }
}
