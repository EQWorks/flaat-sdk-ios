import Foundation

class FlaatAPI {

    class func uploadReport(_ report: TCNReport, completion: @escaping (APIResult<Void>) -> Void) {
        guard let serializedJson = try? JSONSerialization.data(withJSONObject: report.json()) else {
            completion(APIResult.failure(APIError(message: "Cannot serialize report to JSON")))
            return
        }

        Log.debug("Report json: \(String(data: serializedJson, encoding: .utf8)!)")

        // TODO: properly configure dev/prod endpoint switching
        let requestURL = URL(string: APIEndpoints.dev.tcnReports)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.httpBody = serializedJson

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do {
                guard let response = response as? HTTPURLResponse else {
                    throw APIError(message: "Unknown error when uploading report")
                }

                guard (200 ..< 300) ~= response.statusCode else {
                    throw APIError(message: "Error when uploading report. Status code: \(response.statusCode)")
                }

                guard error == nil else { throw error! }

                completion(APIResult.success(()))
            } catch {
                completion(APIResult.failure(error))
            }
        }.resume()
    }

}
