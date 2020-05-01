import Foundation

struct APIError: Error {
    let message: String
}

typealias JSONObject = [String: Any]
