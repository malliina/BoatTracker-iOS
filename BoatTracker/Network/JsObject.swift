//
//  JsValue.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
// Imported because I use Mapbox's coordinate type as a primitive
import Mapbox

class JsValue {
    let value: AnyObject
    
    init(value: AnyObject) {
        self.value = value
    }
    
}

open class JsObject {
    static func parse(any: Any) throws -> JsObject {
        guard let anyString = any as? String else { throw JsonError.invalid("Not JSON.", any) }
        return try parse(string: anyString)
    }
    
    static func parse(obj: AnyObject) throws -> JsObject {
        guard let dict = obj as? [String: AnyObject] else { throw JsonError.invalid("Not a JSON object.", obj) }
        return JsObject(dict: dict)
    }
    
    static func parse(string: String) throws -> JsObject {
        guard let dict = Json.asJson(string) as? [String: AnyObject] else { throw JsonError.invalid("Not a JSON dictionary.", string) }
        return JsObject(dict: dict)
    }
    
    static func parse(data: Data) throws -> JsObject {
        guard let json = Json.asJson(data) else { throw JsonError.invalid("Not JSON.", data) }
        return try JsObject.parse(obj: json)
    }
    
    let dict: [String: AnyObject]
    
    init(dict: [String: AnyObject]) {
        self.dict = dict
    }
    
    func readInt(_ key: String) throws -> Int { return try read(key) }
    
    func readUInt(_ key: String) throws -> UInt64 { return try read(key) }
    
    func readDouble(_ key: String) throws -> Double { return try read(key) }
    
    func readString(_ key: String) throws -> String { return try read(key) }
    
    func timestampMillis(_ key: String) throws -> Date { return Date(timeIntervalSince1970: try readDouble(key) / 1000) }
    
    func coord(_ key: String) throws -> CLLocationCoordinate2D {
        let c = try readObject(key)
        return CLLocationCoordinate2D(latitude: try c.readDouble("lat"), longitude: try c.readDouble("lng"))
    }
    
    func readObject(_ key: String) throws -> JsObject {
        let dict: [String: AnyObject] = try read(key)
        return JsObject(dict: dict)
    }
    
    func readObj<T>(_ key: String, parse: (JsObject) throws -> T) throws -> T {
        let obj = try readObject(key)
        return try parse(obj)
    }
    
    func readObjectArray<T>(_ key: String, each: (JsObject) throws -> T) throws -> [T] {
        let arr: [AnyObject] = try read(key)
        return try arr.map { (anyObj) -> T in
            try each(try JsObject.parse(obj: anyObj))
        }
    }
    
    func read<T>(_ key: String) throws -> T {
        guard let t: T = try readOpt(T.self, key) else { throw JsonError.missing(key) }
        return t
    }
    
    /// Pass the first parameter like CustomType.self
    func readOpt<T>(_ t: T.Type, _ key: String) throws -> T? {
        let raw = dict[key]
        guard let value = raw else { return nil }
        guard let t = value as? T else { throw JsonError.invalid(key, value) }
        return t
    }
    
    func nonEmptyString(_ key: String) throws -> String? {
        guard let s = try readOpt(String.self, key) else { return nil }
        let trimmed = s.trim()
        return trimmed.count > 0 ? trimmed : nil
    }
    
    func stringify(pretty: Bool = true) -> String {
        return Json.stringifyObject(dict)!
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
