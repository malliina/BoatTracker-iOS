//
//  Json.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

open class Json {
    static func asJsonDict(_ input: String) throws -> JsObject {
        if let dict = Json.asJson(input) as? [String: AnyObject] {
            return JsObject(dict: dict)
        } else {
            throw JsonError.invalid("Not a JSON dictionary.", input)
        }
    }
    
    open static func asJson(_ input: String) -> AnyObject? {
        if let data = input.data(using: String.Encoding.utf8, allowLossyConversion: false), let json = asJson(data) {
            return json
        }
        return nil
    }
    
    open static func asJson(_ data: Data) -> AnyObject? {
        let attempt = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
        return attempt as AnyObject?
    }
    
    open static func stringifyObject(_ value: [String: AnyObject], prettyPrinted: Bool = true) -> String? {
        return stringify(value as AnyObject, prettyPrinted: prettyPrinted)
    }
    
    open static func stringify(_ value: AnyObject, prettyPrinted: Bool = true) -> String? {
        //        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        let options = JSONSerialization.WritingOptions.prettyPrinted
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: options) {
                return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
            }
        }
        return nil
    }
    
    static func readString(_ obj: NSDictionary, _ key: String) throws -> String {
        return try readOrFail(obj, key)
    }
    
    static func readInt(_ obj: NSDictionary, _ key: String) throws -> Int {
        return try readOrFail(obj, key)
    }
    
    static func readOrFail<T>(_ obj: NSDictionary, _ key: String) throws -> T {
        let raw = obj[key]
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
}
