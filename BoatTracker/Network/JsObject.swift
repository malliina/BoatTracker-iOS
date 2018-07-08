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
    
    static func parse(string: String) throws -> JsObject {
        if let dict = Json.asJson(string) as? [String: AnyObject] {
            return JsObject(dict: dict)
        } else {
            throw JsonError.invalid("Not a JSON dictionary.", string)
        }
    }
    
    let dict: [String: AnyObject]
    
    init(dict: [String: AnyObject]) {
        self.dict = dict
    }
    
    func readInt(_ key: String) throws -> Int { return try read(key) }
    
    func readString(_ key: String) throws -> String { return try read(key) }
    
    func readObject(_ key: String) throws -> JsObject {
        let dict: [String: AnyObject] = try read(key)
        return JsObject(dict: dict)
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
