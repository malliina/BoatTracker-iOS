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
    
    func testWriteJson() throws {
        try Json.shared.write(from: VesselMeta(mmsi: Mmsi("boat"), name: "Na", heading: 12))
    }
    
    func testKeychain() throws {
        let kc = Keychain.shared
        XCTAssertNil(try kc.findToken())
        let initial = AccessToken("abc")
        try kc.use(token: initial)
        XCTAssertEqual(try kc.readToken(), initial)
        let updated = AccessToken("def")
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
