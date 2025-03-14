import BoatTracker
import XCTest

@testable import BoatTracker

struct Joo: Codable {
  let distance: Distance
  let distance2: Distance
  let distance3: Distance
}

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
    let isSuccess = true  // AppDelegate.initMapboxToken()
    XCTAssert(isSuccess)
  }

  func testWriteJson() throws {
    let _ = try Json.shared.write(from: VesselMeta(mmsi: Mmsi("boat"), name: "Na", heading: 12))
    XCTAssert(true)
  }

  func testDistance() throws {
    let json = Json.shared
    let v = Joo(distance: 0.0.meters, distance2: 1.0.meters, distance3: 2.0.meters)
    let obj = try json.write(from: v)
    let back = try json.parse(Joo.self, from: obj)
    XCTAssert(back.distance == 0.meters)
  }
  
  func testTokenCodec() throws {
    let token = PushPayload(token: PushToken("t1"), device: TokenType.startLiveActivity)
    let obj = try Json.shared.write(from: token)
    let device = obj["device"]!!.string!
    XCTAssertEqual(device, "ios-activity-start")
  }

  func testKeychain() throws {
    let kc = Keychain.shared
    //XCTAssertNil(try kc.findToken())
    let initial = AccessToken("abc")
    try kc.use(token: initial)
    XCTAssertEqual(try kc.readToken(), initial)
    let updated = AccessToken("def")
    try kc.use(token: updated)
    XCTAssertEqual(try kc.readToken(), updated)
    try kc.delete()
    XCTAssertNil(try kc.findToken())
  }

  func testReadConf() throws {
    try BoatPreviews.shared.readLocalConf()
  }

  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }
}
