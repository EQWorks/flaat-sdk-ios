import Foundation

public enum FlaatError: Error {

    case invalidConfiguration(message: String)
    case dataStoreError(cause: Error? = nil)
    case apiError(cause: Error? = nil)
}

public struct FlaatConfiguration {

    public enum BuildConfig {
        case debug
        case release
    }

    public var apiKey: String

    public var buildConfig: BuildConfig = .release

    public var logLevel: LogLevel = .info

    /// Valid values must be between 1 and 24 hours.
    public var reportFetchInterval: TimeInterval = 60 * 60 * 4

    /// Valid values must be between 5 and 20 minutes.
    public var tcnRotationInterval: TimeInterval = 60 * 15

    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}

public typealias RiskLevel = Double

public enum ExposureStatus {

    /// No exposure doesn't guarantee that there were no contacts with infected individuals.
    /// It only indicates that there were no recorded contacts which meet minimal criteria for health risk.
    case noExposure

    /// There were contacts with infected individuals which meet the criteria for health risk.
    case confirmedContacts(exposures: [ExposureDetails])
}

public struct ExposureDetails {

    public let date: Date
    public let duration: TimeInterval
    public let riskLevel: RiskLevel
}

public struct ReportMetadata {

    public static func `default`() -> Self {
        return Self()
    }

    public var daysToInclude: Int = 21
    public var validationInfo: [String: String] = [:]
    public var patientRiskLevel: RiskLevel = 1.0
}

// MARK: - FlaatService: Public Interface

public class FlaatService {

    public static let shared = FlaatService()

    private var configuration: FlaatConfiguration!
    private var bluetoothMonitor: BluetoothMonitor!
    private var flaatAPI: FlaatAPIServer!
    private var dataStore: TCNDataStore!

    private init() {
        do {
            dataStore = try TCNDataStoreCoreData()
        } catch {
            Log.error("Data store cannot be initialized due to error: \(error)")
        }
    }

    /// Launches Bluetooth monitoring and TCN exchange, as well as periodic downloading of reports from Flaat backend.
    public func startTracing(configuration: FlaatConfiguration) throws {
        try validateConfiguration(configuration)
        self.configuration = configuration
        
        guard dataStore != nil else {
            throw FlaatError.dataStoreError()
        }

        flaatAPI = FlaatServerImpl(apiKey: configuration.apiKey, buildConfig: configuration.buildConfig)
        Log.logLevel = configuration.logLevel

        do {
            let keyStore = TCNKeyStoreImpl(secureStore: KeychainKeyStore(), unsecureKeyStore: UserDefaultsStore())
            bluetoothMonitor = try BluetoothMonitor(dataStore: dataStore, keyStore: keyStore, tcnRotationInterval: configuration.tcnRotationInterval)
            try bluetoothMonitor.startMonitoring()
            launchPeriodicReportDownloads()
        } catch {
            throw FlaatError.dataStoreError(cause: error)
        }
    }

    public func uploadReport(metadata: ReportMetadata, completion: @escaping (Error?) -> Void) {
        let reportUploader = ReportUploader(flaatAPI: flaatAPI)
        do {
            let tcnReport = try bluetoothMonitor.generateReport()
            let savedReport = try dataStore.saveOutgoingReport(tcnReport, dateCreated: Date())
            let validationPin = metadata.validationInfo["pin"] ?? "no-pin"

            reportUploader.uploadReport(days: metadata.daysToInclude, tcnReport: tcnReport, validationPin: validationPin, completion: { error in
                if error != nil {
                    do {
                        try self.dataStore.markReportSubmitted(savedReport, onDate: Date())
                    } catch {
                        Log.error("Cannot mark report submitted in the data store")
                    }
                }
                completion(error)
            })
        } catch {
            completion(error)
            return
        }
    }

    public func downloadAndAnalyzeReports(completion: @escaping (_ infected: Result<ExposureStatus, Error>) -> Void) {
        let reportAnalyzer = ReportAnalyzer(dataStore: dataStore, flaatAPI: flaatAPI)
        reportAnalyzer.downloadAndAnalyzeReports(completion: completion)
    }

    public func getCurrentStatus() throws -> ExposureStatus {
        let reports = try dataStore.fetchIncomingReports(processed: true)

        if reports.isEmpty {
            return .noExposure
        } else {
            let exposures = try RiskCalculator.convertReportsToExposures(reports)
            return .confirmedContacts(exposures: exposures)
        }
    }
}

// MARK: - FlaatService: Private

extension FlaatService {

    private func validateConfiguration(_ configuration: FlaatConfiguration) throws {
        guard !configuration.apiKey.isEmpty else {
            throw FlaatError.invalidConfiguration(message: "No API key provided")
        }

        if configuration.buildConfig == .release {
            let validReportFetchIntervals = (60 * 60 * 1)...(60 * 60 * 24)
            guard validReportFetchIntervals ~= Int(configuration.reportFetchInterval) else {
                throw FlaatError.invalidConfiguration(message: "Report fetch interval is out of valid range")
            }

            let validTCNRotationIntervals = (60 * 5)...(60 * 20)
            guard validTCNRotationIntervals ~= Int(configuration.tcnRotationInterval) else {
                throw FlaatError.invalidConfiguration(message: "TCN rotation interval is out of valid range")
            }
        }
    }

    private func launchPeriodicReportDownloads() {
        Timer.scheduledTimer(withTimeInterval: configuration.reportFetchInterval, repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            self.downloadAndAnalyzeReports { (result) in
                Log.info("Scheduled report fetch result: \(result)")
            }
        }
    }
}
