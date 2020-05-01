import Foundation
import CoreData
import TCNClient

extension OutgoingTCNReportImpl: OutgoingTCNReport {

    @nonobjc class func fetchRequest() -> NSFetchRequest<OutgoingTCNReportImpl> {
        return NSFetchRequest<OutgoingTCNReportImpl>(entityName: "OutgoingTCNReport")
    }

    @NSManaged var reportData: Data
    @NSManaged var dateCreated: Date
    @NSManaged var dateSubmitted: Date?

    var signedReport: SignedReport {
        return try! SignedReport(serializedData: reportData)
    }
}
