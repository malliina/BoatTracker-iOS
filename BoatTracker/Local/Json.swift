//
//  Json.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 01/06/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation

class Json {
    static let shared = Json()
    
    let log = LoggerFactory.shared.system(Json.self)
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    func asData(dict: [String: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }
    
    func read<T: Decodable>(_ t: T.Type, dict: [String: Any]) throws -> T {
        let json = try asData(dict: dict)
        return try decoder.decode(t, from: json)
    }
    
    func write<T: Encodable>(from: T) throws -> [String: Any] {
        let data = try encoder.encode(from)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = json as? [String: Any] else {
            throw JsonError.notJson(data)
        }
        return dict
    }
}

extension Data {
    func validate<T: Decodable>(_ t: T.Type) throws -> T {
        return try Json.shared.decoder.decode(t, from: self)
    }
}
