import ActivityKit

struct BoatWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    let message: String
    let distance: Distance
    let duration: Duration
    let address: String?
    let coord: Coord?
    let image: String?
  }
  let boatName: BoatName
  let trackName: TrackName
}
