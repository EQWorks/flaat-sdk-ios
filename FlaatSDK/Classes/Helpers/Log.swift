import Foundation

struct Log {

    enum Level: Int {
        case debug
        case info
        case warning
        case error

        static func <=(_ left: Level, _ right: Level) -> Bool {
            return left.rawValue <= right.rawValue
        }
    }

    #if DEBUG
    static var logLevel: Level = .debug
    #else
    static var logLevel: Level = .info
    #endif

    static func debug(_ logMessage: String) {
        guard logLevel <= .debug else { return }
        emitLog(prefix: "DEBUG", logMessage)
    }

    static func info(_ logMessage: String) {
        guard logLevel <= .debug else { return }
        emitLog(prefix: "INFO", logMessage)
    }

    static func warning(_ logMessage: String) {
        guard logLevel <= .debug else { return }
        emitLog(prefix: "WARNING", logMessage)
    }

    static func error(_ logMessage: String) {
        guard logLevel <= .debug else { return }
        emitLog(prefix: "ERROR", logMessage)
    }

    private static func emitLog(prefix: String, _ logMessage: String) {
        NSLog("[FlaatSDK] \(prefix): \(logMessage)")
    }
}
