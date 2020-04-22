import Foundation

enum APIResult<T> {
    case success(T)
    case failure(Error)
}

struct APIEndpoints {

    struct dev {
        static let login = "https://api.flaat.io/dev/login"
        static let tcnReports = "https://api.flaat.io/dev/tcnreport"
    }

    struct prod {
        static let tcnReports = "https://api.flaat.io/prod/tcnreport"
    }
}

struct APIError: Error {
    let message: String
}

typealias JSONObject = [String: Any]
