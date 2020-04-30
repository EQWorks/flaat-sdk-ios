import Foundation
import TCNClient
import CoreData

class TCNDataStoreCoreData: TCNDataStore {

    let persistentContainer: NSPersistentContainer

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

    func saveEncounteredTCN(_ tcn: TemporaryContactNumber, timestamp: Date, rssi: Double) throws {

        // TODO: fetch object if it exist and update it

        let managedObjectContext = persistentContainer.viewContext
        let newTCN = NSEntityDescription.insertNewObject(forEntityName: "TCNEncounter", into: managedObjectContext) as! TCNEncounterImpl
        newTCN.tcnBytes = tcn.bytes
        newTCN.firstTime = timestamp
        newTCN.lastTime = timestamp
        newTCN.closestRSSI = rssi

        do {
            try managedObjectContext.save()
        } catch {
            Log.error("Failed to save new TCN encounter: \(error)")
            throw TCNDataError.writeFailure
        }
    }

    func loadTCNEncounters(fromDate: Date?) throws -> [TCNEncounter] {
        let fetchRequest = NSFetchRequest<TCNEncounterImpl>(entityName: "TCNEncounter")

        do {
            let fetchedEncounters = try persistentContainer.viewContext.fetch(fetchRequest)
            return fetchedEncounters
        } catch {
            Log.error("Failed to fetch TCN encounters: \(error)")
            throw TCNDataError.readFailure
        }
    }

    func cleanupOldEncounters(untilDate: Date) throws {

    }

    func saveOutgoingReport(_ report: OutgoingTCNReport) throws {

    }

    func fetchOutgoingReports(onlyNotSent: Bool) throws -> [OutgoingTCNReport] {
        return []
    }

    func saveIncomingReport(_ report: IncomingTCNReport) throws {

    }

    func fetchIncomingReports(onlyUnprocessed: Bool) throws -> [IncomingTCNReport] {
        return []
    }

    func deleteIncomingReports(_ reports: [IncomingTCNReport]) throws {

    }

    func linkEncounters(_ encounters: [TCNEncounter], toReport report: IncomingTCNReport) throws {

    }

}
