//
//  HttpResponse.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class HttpResponse {
    static let log = LoggerFactory.shared.network(HttpResponse.self)
    
    let http: HTTPURLResponse
    let data: Data
    
    var statusCode: Int { http.statusCode }
    var isStatusOK: Bool { statusCode >= 200 && statusCode < 300 }

    var errors: [SingleError] {
        get {
            let decoder = JSONDecoder()
            do {
                return try decoder.decode(Errors.self, from: data).errors
            } catch {
                HttpResponse.log.error("HTTP response failed, and failed to parse error model. \(error.describe)")
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
    let url: URL
    let code: Int
    let errors: [SingleError]
    
    var message: String? { errors.first?.message }
    
    init(url: URL, code: Int, errors: [SingleError]) {
        self.url = url
        self.code = code
        self.errors = errors
    }
}
