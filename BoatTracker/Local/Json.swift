
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
        let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
        guard let dict = json as? [String: Any?] else {
            throw JsonError.notJson(data)
        }
        log.info("Dict \(dict)")
        return dict.mapValues { $0.flatMap(parse(rawValue:)) }
        
    }
    /// Turf parses doubles to bool if the value is 0 or 1 in a dict like [String: Any?].
    /// To workaround, we manually parse & check if Any is a number before checking if it's a bool (rearranged from Turf sources).
    private func parse(rawValue: Any) -> JSONValue? {
        if let number = rawValue as? NSNumber { // must be before bool check
            return .number(number.doubleValue)
        } else if let bool = rawValue as? Bool {
            return .boolean(bool)
        } else if let string = rawValue as? String {
            return .string(string)
        } else if let rawArray = rawValue as? JSONArray.RawValue {
            return .array(rawArray.compactMap { e in e }.map { e in parse(rawValue: e) })
        } else if let rawObject = rawValue as? JSONObject.RawValue {
            return .object(rawObject.mapValues { $0.flatMap(parse(rawValue:)) })
        } else {
            return nil
        }
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
