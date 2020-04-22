//
//  FlaatService.swift
//  FlaatSDK
//
//  Created by Eugene Kolpakov on 2020-04-21.
//

import Foundation

public class FlaatService {

    public class func launch(apiKey: String, logLevel: LogLevel = .info) {
        FlaatAPI.apiKey = apiKey
        Log.logLevel = logLevel

        // TODO: launch Bluetooth service
    }

    public class func uploadReport(days: Int = 21, validationPin: String, completion: @escaping (Error?) -> Void) {
        let reportUploader = ReportUploader()
        reportUploader.uploadReport(days: days, validationPin: validationPin, completion: completion)
    }

}
