//
//  JsValue.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

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
    
    func readDouble(_ key: String) throws -> Double { return try read(key) }
    
    func readString(_ key: String) throws -> String { return try read(key) }
    
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
        let raw = dict[key]
        if let t = raw as? T {
            return t
        } else {
            if let any = raw {
                throw JsonError.invalid(key, any)
            } else {
                throw JsonError.missing(key)
            }
        }
    }
    
    func stringify(pretty: Bool = true) -> String {
        return Json.stringifyObject(dict)!
    }
}
