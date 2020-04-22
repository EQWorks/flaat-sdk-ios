import Foundation

internal typealias DataTaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

internal class FlaatAPI {

    static let `default` = FlaatAPI()

    internal static var apiKey: String?

    private var accessToken: String?

    func uploadReport(_ report: TCNReport, completion: @escaping (APIResult<Void>) -> Void) {
        // TODO: properly configure dev/prod endpoint switching
        prepareAndRunRequest(url: APIEndpoints.dev.tcnReports, method: "POST", params: report.json()) { (data, response, error) in
            if let error = error {
                completion(APIResult.failure(error))
            } else {
                completion(APIResult.success(()))
            }
        }
    }

    private func prepareAndRunRequest(url: String, method: String, params: [String: Any], requireAuth: Bool = true, completion: @escaping DataTaskCompletionHandler) {
        Log.debug("Sending request to \(url)...")

        let requestURL = URL(string: url)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = method

        if method == "GET" {
            // TODO: set parameters for GET request
            
        } else {
            guard let serializedJson = try? JSONSerialization.data(withJSONObject: params) else {
                completion(nil, nil, APIError(message: "Cannot serialize request parameters to JSON"))
                return
            }
            request.httpBody = serializedJson

            Log.debug("Request body: \(String(data: serializedJson, encoding: .utf8)!)")
        }

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
        guard let apiKey = FlaatAPI.apiKey, !apiKey.isEmpty else {
            completion(APIError(message: "API key is missing"))
            return
        }

        let deviceId = UIDevice.current.identifierForVendor ?? UUID()
        let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) ?? ProcessInfo.processInfo.processName

        let loginParams: [String: Any] = [
            "device_id": deviceId.uuidString,
            "app_name": appName,
            "access_key": apiKey]

        prepareAndRunRequest(url: APIEndpoints.dev.login, method: "POST", params: loginParams, requireAuth: false) { (data, response, error) in
            guard error != nil else {
                completion(error)
                return
            }

            guard let data = data, !data.isEmpty,
                  let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let token = dict["token"] as? String, !token.isEmpty else {
                completion(APIError(message: "No token returned in login response"))
                return
            }

            self.accessToken = token
            completion(nil)
        }

    }
}
