import Foundation
import TCNClient
import CoreData

class TCNDataStoreCoreData: TCNDataStore {

    let persistentContainer: NSPersistentContainer

    private var managedObjectContext: NSManagedObjectContext { return persistentContainer.viewContext }

    init() throws {
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: "TCNDataStore", withExtension:"momd") else {
            Log.error("Cannot find CoreData model file for TCN Data Store")
            throw TCNDataError.initializationFailure
        }

        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            Log.error("Error initializing data model from: \(modelURL)")
            throw TCNDataError.initializationFailure
        }

        let container = NSPersistentContainer(name: "TCNDataStore", managedObjectModel: model)
        container.loadPersistentStores { description, error in
            if let error = error {
                Log.error("Unable to load persistent stores: \(error)")
            }
        }

        self.persistentContainer = container
    }

    func saveEncounteredTCN(_ tcn: TemporaryContactNumber, timestamp: Date, distance: Double) throws {
        let tcnBase64 = tcn.bytes.base64EncodedString()

        let fetchRequest = NSFetchRequest<TCNEncounterImpl>(entityName: "TCNEncounter")
        fetchRequest.predicate = NSPredicate(format: "tcnBase64 == %@", tcnBase64)

        let existingTCN: TCNEncounterImpl?
        do {
            let fetchedEncounters = try persistentContainer.viewContext.fetch(fetchRequest)
            existingTCN = fetchedEncounters.first
        } catch {
            Log.error("Failed to fetch TCN encounters with given TCN: \(error)")
            throw TCNDataError.readFailure
        }

        if let existingTCN = existingTCN {
            existingTCN.lastTime = timestamp
            existingTCN.closestDistance = min(distance, existingTCN.closestDistance)
        } else {
            let newTCN = NSEntityDescription.insertNewObject(forEntityName: "TCNEncounter", into: managedObjectContext) as! TCNEncounterImpl
            newTCN.tcnBase64 = tcn.bytes.base64EncodedString()
            newTCN.firstTime = timestamp
            newTCN.lastTime = timestamp
            newTCN.closestDistance = distance
        }

        // TODO: improve saving to ensure it's not done too frequently
        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

    func loadTCNEncounters(fromDate: Date?) throws -> [TCNEncounter] {
        let fetchRequest = NSFetchRequest<TCNEncounterImpl>(entityName: "TCNEncounter")

        if let fromDate = fromDate {
            fetchRequest.predicate = NSPredicate(format: "lastTime >= %@", argumentArray: [fromDate])
        }

        do {
            let fetchedEncounters = try managedObjectContext.fetch(fetchRequest)
            return fetchedEncounters
        } catch {
            throw TCNDataError.readFailure
        }
    }

    func cleanupOldEncounters(untilDate: Date) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TCNEncounter")
         // do not delete encounters with linked reports
        fetchRequest.predicate = NSPredicate(format: "lastTime <= %@ AND linkedReportImpl == nil", argumentArray: [untilDate])
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try managedObjectContext.execute(deleteRequest)
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

    func saveOutgoingReport(_ report: SignedReport, dateCreated: Date) throws -> OutgoingTCNReport  {
        let newReport = NSEntityDescription.insertNewObject(forEntityName: "OutgoingTCNReport", into: managedObjectContext) as! OutgoingTCNReportImpl

        do {
            newReport.reportData = try report.serializedData()
        } catch {
            throw TCNDataError.invalidDataFormat
        }

        newReport.dateCreated = dateCreated

        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }

        return newReport
    }

    func markReportSubmitted(_ report: OutgoingTCNReport, onDate date: Date) throws {
        guard let report = report as? OutgoingTCNReportImpl else {
            throw TCNDataError.invalidDataFormat
        }

        report.dateSubmitted = date

        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

    func fetchOutgoingReports(onlyNotSent: Bool) throws -> [OutgoingTCNReport] {
        let fetchRequest = NSFetchRequest<OutgoingTCNReportImpl>(entityName: "OutgoingTCNReport")

        if onlyNotSent {
            fetchRequest.predicate = NSPredicate(format: "dateSubmitted == nil")
        }

        do {
            let fetchedReports = try managedObjectContext.fetch(fetchRequest)
            return fetchedReports
        } catch {
            throw TCNDataError.readFailure
        }
    }

    func saveIncomingReports(_ reports: [TCNClient.Report], dateReceived: Date) throws {
        for report in reports {
            let newReport = NSEntityDescription.insertNewObject(forEntityName: "IncomingTCNReport", into: managedObjectContext) as! IncomingTCNReportImpl

            do {
                newReport.reportData = try report.serializedData()
            } catch {
                throw TCNDataError.invalidDataFormat
            }

            newReport.dateReceived = dateReceived
        }

        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

    func fetchIncomingReports(processed: Bool) throws -> [IncomingTCNReport] {
        let fetchRequest = NSFetchRequest<IncomingTCNReportImpl>(entityName: "IncomingTCNReport")

        fetchRequest.predicate = NSPredicate(format: "processed == %@", processed)

        do {
            let fetchedReports = try managedObjectContext.fetch(fetchRequest)
            return fetchedReports
        } catch {
            throw TCNDataError.readFailure
        }
    }

    func deleteIncomingReports(_ reports: [IncomingTCNReport]) throws {
        for report in reports {
            if let report = report as? IncomingTCNReportImpl {
                managedObjectContext.delete(report)
            }
        }

        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

    func linkEncounters(_ encounters: [TCNEncounter], toReport report: IncomingTCNReport) throws {
        guard let encounters = encounters as? [TCNEncounterImpl] else {
            Log.error("Invalid objects passed as TCN encounters")
            throw TCNDataError.invalidDataFormat
        }

        guard let report = report as? IncomingTCNReportImpl else {
            Log.error("Invalid object passed as incoming report")
            throw TCNDataError.invalidDataFormat
        }

        report.tcnEncounters = NSSet(arrayLiteral: encounters)
        report.processed = true

        do {
            try managedObjectContext.save()
        } catch {
            throw TCNDataError.writeFailure
        }
    }

}
