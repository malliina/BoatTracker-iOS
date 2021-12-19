//
//  Json.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 01/06/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Turf

class Json {
    static let shared = Json()
    
    let log = LoggerFactory.shared.system(Json.self)
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func asData(dict: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }
    
    func parse<T: Decodable>(_ t: T.Type, from: JSONObject) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: from.rawValue, options: .prettyPrinted)
        return try parse(t, data: data)
    }
    
    func parse<T: Decodable>(_ t: T.Type, data: Data) throws -> T {
        return try decoder.decode(t, from: data)
    }
    
    func read<T: Decodable>(_ t: T.Type, dict: [String: Any]) throws -> T {
        let json = try asData(dict: dict)
        return try decoder.decode(t, from: json)
    }
    
    func write<T: Encodable>(from: T) throws -> JSONObject {
        let data = try encoder.encode(from)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = json as? [String: Any?], let obj = JSONObject(rawValue: dict) else {
            throw JsonError.notJson(data)
        }
        return obj
    }
    
    func stringify<T: Encodable>(_ t: T) throws -> String {
        let data = try encoder.encode(t)
        guard let asString = String(data: data, encoding: .utf8) else { throw JsonError.notJson(data) }
        return asString
    }
}

extension Data {
    func validate<T: Decodable>(_ t: T.Type) throws -> T {
        try Json.shared.decoder.decode(t, from: self)
    }
}
