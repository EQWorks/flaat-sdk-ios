import Foundation


internal class PrivateKitLocationReader {

    private var sortedLocations: [GeoLocationRecord] = []

    public func readAllLoggedLocations() -> [GeoLocationRecord] {

        // TODO: make thread-safe or just add doc that it's not thread-safe
        guard sortedLocations.isEmpty else { return sortedLocations }

        let locationRecords = scrapeLocationFiles()
            .compactMap { GeoLocationRecord.recordFromDict($0) }
            .sorted { $0.timestamp <= $1.timestamp }

        return locationRecords
    }

    private func scrapeLocationFiles() -> [[String: Any]] {
        let fileManager = FileManager.default
        let appSupportDirURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)

        guard let appSupportDirURL = appSupportDirURLs.first, let bundleID = Bundle.main.bundleIdentifier else { return [] }
        let asyncStorageDirURL = appSupportDirURL.appendingPathComponent(bundleID).appendingPathComponent("RCTAsyncLocalStorage_V1")

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: asyncStorageDirURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            Log.error("Unable to read Async Storage directory to get location logs - directory doesn't exist")
            return []
        }

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: asyncStorageDirURL, includingPropertiesForKeys: nil, options:[])

            let allLocationDicts = fileURLs.flatMap { (fileURL) -> [[String: Any]] in
                guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) && !isDirectory.boolValue else { return [] }
                return readFile(fileURL)
            }

            return allLocationDicts
        } catch {
            Log.error("Cannot read log files: \(error)")
            return []
        }
    }

    private func readFile(_ fileURL: URL) -> [[String: Any]] {
        Log.debug("Parsing potential file with locations: \(fileURL.path)")
        do {
            let fileContentsJSON = try JSONSerialization.jsonObject(with: try Data(contentsOf: fileURL), options:[])

            guard let locationDicts = fileContentsJSON as? [[String: Any]],
                  let firstDict = locationDicts.first,
                  firstDict["latitude"] != nil,
                  firstDict["longitude"] != nil,
                  firstDict["time"] != nil else {
                Log.debug("File \(fileURL.lastPathComponent) doesn't seem to contain location data")
                return []
            }

            return locationDicts
        } catch {
            Log.error("Cannot read log file \(fileURL.path): \(error)")
            return []
        }
    }
}

extension GeoLocationRecord {

    static func recordFromDict(_ dict: [String: Any]) -> GeoLocationRecord? {
        guard let latitude = dict["latitude"] as? Double,
              let longitude = dict["longitude"] as? Double,
              let timestampMs = dict["time"] as? Int64 else {
            return nil
        }

        return GeoLocationRecord(location: GeoLocation(latitude: latitude, longitude: longitude), timestamp: Date(timeIntervalSince1970: Double(timestampMs) / 1000.0))
    }
}
