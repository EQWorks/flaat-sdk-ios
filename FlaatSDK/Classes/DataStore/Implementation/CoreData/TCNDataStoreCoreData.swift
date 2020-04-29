import Foundation
import TCNClient
import CoreData

class TCNDataStoreCoreData: TCNDataStore {

    lazy var persistentContainer: NSPersistentContainer = {
        // TODO: load model by path inside the framework
        let container = NSPersistentContainer(name: "TCNDataStore")
        container.loadPersistentStores { description, error in
            if let error = error {
                Log.error("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    func saveEncounteredTCN(_ tcn: TemporaryContactNumber, timestamp: Date, rssi: Double) throws {

    }

    func loadTCNEncounters(fromDate: Date?) throws -> [TCNEncounter] {
        return []
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
