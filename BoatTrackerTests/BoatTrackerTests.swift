//
//  BoatTrackerTests.swift
//  BoatTrackerTests
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import XCTest
import BoatTracker

@testable import BoatTracker

class BoatTrackerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitToken() throws {
        let isSuccess = AppDelegate.initMapboxToken()
        XCTAssert(isSuccess)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let input = "{\"a\": 42, \"b\": {\"sub\": \"hello\"}}"
        let obj = try JsObject.parse(string: input)
        let actual = try obj.readInt("a")
        XCTAssert(actual == 42)
        let b = try obj.readObject("b")
        let sub = try b.readString("sub")
        XCTAssert(sub == "hello")
        XCTAssertThrowsError(try obj.readString("nonexistent"), "Reading nonexistent key throws") { (error) in
            if case JsonError.missing(_) = error {
                
            } else {
                XCTAssert(false, "Wrong error type.")
            }
        }
    }
    
    func testDictToJson() throws {
        let dict = ["boatName": "abc" as AnyObject]
        let data = try JSONSerialization.data(withJSONObject: dict, options: [])
        if let json = Json.asJson(data) {
            let str = Json.stringify(json)
            XCTAssert(str != nil && !(str?.isEmpty ?? false))
        } else {
            XCTAssert(false, "Not JSON.")
        }
    }
    
    func testKeychain() throws {
        let kc = Keychain.shared
        XCTAssertNil(try kc.findToken())
        let initial = AccessToken(token: "abc")
        try kc.use(token: initial)
        XCTAssertEqual(try kc.readToken(), initial)
        let updated = AccessToken(token: "def")
        try kc.use(token: updated)
        XCTAssertEqual(try kc.readToken(), updated)
        try kc.delete()
        XCTAssertNil(try kc.findToken())
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
