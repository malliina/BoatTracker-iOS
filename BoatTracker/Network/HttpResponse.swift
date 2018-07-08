//
//  HttpResponse.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class HttpResponse {
    let http: HTTPURLResponse
    let data: Data
    
    var statusCode: Int { return http.statusCode }
    var isStatusOK: Bool { return statusCode >= 200 && statusCode < 300 }
    var json: NSDictionary? { return Json.asJson(data) as? NSDictionary }
    var errors: [SingleError] {
        get {
            if let json = json, let errors = json["errors"] as? [NSDictionary] {
                return errors.compactMap({ (dict) -> SingleError? in
                    if let key = dict["key"] as? String, let message = dict["message"] as? String {
                        return SingleError(key: key, message: message)
                    } else {
                        return nil
                    }
                })
            } else {
                return []
            }
        }
    }
    var isTokenExpired: Bool {
        return errors.contains { $0.key == "token_expired" }
    }
    
    init(http: HTTPURLResponse, data: Data) {
        self.http = http
        self.data = data
    }
}

class ResponseDetails {
    let resource: String
    let code: Int
    let message: String?
    
    init(resource: String, code: Int, message: String?) {
        self.resource = resource
        self.code = code
        self.message = message
    }
}
