import ActivityKit

struct BoatWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var boatName: String
    var message: String
    var distance: Distance
//    var duration: Duration
  }

  // Fixed non-changing properties about your activity go here!
  var name: String
}
