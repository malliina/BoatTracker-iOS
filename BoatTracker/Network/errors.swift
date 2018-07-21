//
//  errors.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class SingleError {
    let key: String
    let message: String
    
    convenience init(message: String) {
        self.init(key: "error", message: message)
    }
    
    init(key: String, message: String) {
        self.key = key
        self.message = message
    }
}

class RequestFailure {
    let url: URL
    let code: Int
    let data: Data?
    
    init(url: URL, code: Int, data: Data?) {
        self.url = url
        self.code = code
        self.data = data
    }
}

enum JsonError: Error {
    static let Key = "error"
    case notJson(Data)
    case missing(String)
    case invalid(String, Any)
    
    var describe: String {
        switch self {
        case .missing(let key):
            return "Key not found: '\(key)'."
        case .invalid(let key, let actual):
            return "Invalid '\(key)' value: '\(actual)'."
        case .notJson( _):
            return "Invalid response format. Expected JSON."
        }
    }
}

enum AppError: Error {
    case parseError(JsonError)
    case responseFailure(ResponseDetails)
    case networkFailure(RequestFailure)
    case simpleError(SingleError)
    case tokenError(Error)
    
    var describe: String {
        switch self {
        case .parseError(let json):
            return json.describe
        case .responseFailure(let details):
            let code = details.code
            switch code {
            case 400:
                return "Bad request: \(details.url)."
            case 401:
                return "Check your username/password."
            case 404:
                return "Resource not found: \(details.url)."
            case 406:
                return "Please update this app to the latest version to continue. This version is no longer supported."
            default:
                if let message = details.message {
                    return "Error code: \(code), message: \(message)"
                } else {
                    return "Error code: \(code)."
                }
            }
        case .networkFailure( _):
            return "A network error occurred."
        case .tokenError(_):
            return "A network error occurred."
        case .simpleError(let message):
            return message.message
        }
    }
    
    var stringifyDetailed: String {
        switch self {
        case .networkFailure(let request):
            return "Unable to connect to \(request.url.description), status code \(request.code)."
        default:
            return self.describe
        }
    }
    
    static func simple(_ message: String) -> AppError {
        return AppError.simpleError(SingleError(key: "error", message: message))
    }
}
