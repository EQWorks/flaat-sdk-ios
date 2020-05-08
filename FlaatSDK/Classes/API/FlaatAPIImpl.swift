import Foundation

typealias DataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

protocol FlaatAPIServer {

    func uploadTCNReport(_ report: TCNReport, completion: @escaping (Result<Void, Error>) -> Void)
    func downloadTCNReports(locations: [GeoLocation], verified: Bool, fromDate: Date?, completion: @escaping (Result<[Data], Error>) -> Void)

}

class FlaatServerImpl: FlaatAPIServer {

    struct APIEndpoints {

        static let login = "/login"
        static let tcnReports = "/tcnreport"
    }

    private let apiKey: String
    private let buildConfig: FlaatConfiguration.BuildConfig

    private var accessToken: String?

    init(apiKey: String, buildConfig: FlaatConfiguration.BuildConfig = .release) {
        self.apiKey = apiKey
        self.buildConfig = buildConfig
    }

    func uploadTCNReport(_ report: TCNReport, completion: @escaping (Result<Void, Error>) -> Void) {
        prepareAndRunRequest(url: endpointURL(APIEndpoints.tcnReports), method: "POST", params: report.json()) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func downloadTCNReports(locations: [GeoLocation], verified: Bool, fromDate: Date?, completion: @escaping (Result<[Data], Error>) -> Void) {
        var params: [String: Any] = ["verified": verified]

        if let fromDate = fromDate {
            params["fromDate"] = fromDate.timeIntervalSince1970
        }

        if !locations.isEmpty {
            params["locations"] = "[\(locations.map({ $0.geoHash(precision: 3) }).joined(separator: ","))]"
        }

        prepareAndRunRequest(url: endpointURL(APIEndpoints.tcnReports), method: "GET", params: params) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = data else {
                    completion(.failure(APIError(message: "Empty response")))
                    return
                }

                guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let serializedReports = dict["reports"] as? [String] else {
                    completion(.failure(APIError(message: "Cannot parse data in response")))
                    return
                }

                let reports = serializedReports.compactMap { Data(base64Encoded: $0) }
                completion(.success(reports))
            }
        }
    }

    private func prepareAndRunRequest(url: String, method: String, params: [String: Any], requireAuth: Bool = true, completion: @escaping DataTaskCompletionHandler) {
        let request: URLRequest

        do {
            if method == "GET" {
                request = getRequest(url: url, params: params)
            } else {
                request = try jsonRequest(url: url, bodyJson: params, method: method)
            }
        } catch {
            completion(nil, nil, error)
            return
        }

        Log.debug("Sending request to \(url)...")

        performRequest(request, requireAuth: requireAuth) { (data, response, requestError) in
            do {
                guard let response = response as? HTTPURLResponse else {
                    throw APIError(message: "Unknown error when uploading report")
                }

                guard (200 ..< 300) ~= response.statusCode else {
                    throw APIError(message: "Request status code: \(response.statusCode)")
                }

                guard requestError == nil else { throw requestError! }

                completion(data, response, requestError)
            } catch {
                completion(data, response, error)
            }
        }
    }

    private func performRequest(_ request: URLRequest, requireAuth: Bool = true, completion: @escaping DataTaskCompletionHandler) {
        func launchRequestWithAuth() {
            var finalRequest = request

            if requireAuth {
                finalRequest.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
            }

            URLSession.shared.dataTask(with: finalRequest, completionHandler: completion).resume()
        }

        if requireAuth && accessToken == nil {
            fetchToken { (error) in
                guard error == nil else {
                    completion(nil, nil, error)
                    return
                }

                guard self.accessToken != nil else {
                    completion(nil, nil, APIError(message: "Uknown error when getting API access token"))
                    return
                }

                launchRequestWithAuth()
            }
        } else {
            launchRequestWithAuth()
        }
    }

    private func fetchToken(completion: @escaping (Error?) -> Void) {
        guard !apiKey.isEmpty else {
            completion(APIError(message: "API key is missing"))
            return
        }

        let deviceId = UIDevice.current.identifierForVendor ?? UUID()
        let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) ?? ProcessInfo.processInfo.processName

        let loginParams: [String: Any] = [
            "device_id": deviceId.uuidString,
            "app_name": appName,
            "access_key": apiKey]

        prepareAndRunRequest(url: endpointURL(APIEndpoints.login), method: "POST", params: loginParams, requireAuth: false) { (data, response, error) in
            guard error == nil else {
                completion(error)
                return
            }

            guard let data = data, !data.isEmpty,
                  let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let token = dict["token"] as? String, !token.isEmpty else {
                completion(APIError(message: "No token returned in login response"))
                return
            }

            Log.info("Successfully logged in to the API and received access token")

            // TODO: save token to keychain and try to restore it from Keychain on app launch (?)
            self.accessToken = token
            completion(nil)
        }
    }


    private func getRequest(url: String, params: [String: Any]) -> URLRequest {
        let queryItems = params.map { URLQueryItem(name: $0, value: "\($1)") }
        var components = URLComponents(string: url)!
        components.queryItems = queryItems
        let requestURL = components.url!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"

        return request
    }

    private func jsonRequest(url: String, bodyJson: [String: Any], method: String) throws -> URLRequest {
        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = method

        guard let serializedJson = try? JSONSerialization.data(withJSONObject: bodyJson) else {
            throw APIError(message: "Cannot serialize request parameters to JSON")
        }
        request.httpBody = serializedJson
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Log.debug("Request body: \(String(data: serializedJson, encoding: .utf8)!)")

        return request
    }

    private func endpointURL(_ path: String) -> String {
        return buildConfig.serviceBaseURL + path
    }
}

private extension FlaatConfiguration.BuildConfig {

    var serviceBaseURL: String {
        switch self {
        case .debug:
            return "https://api.flaat.io/dev"
        case .release:
            return "https://api.flaat.io/prod"
        }
    }
}
