import Foundation

public enum LogLevel: Int {
    case debug
    case info
    case warning
    case error
}

extension LogLevel {

    static func <=(_ left: LogLevel, _ right: LogLevel) -> Bool {
        return left.rawValue <= right.rawValue
    }

}

struct Log {

    #if DEBUG
    static var logLevel: LogLevel = .debug
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
