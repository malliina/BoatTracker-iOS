import Foundation
import MapboxMaps

class Geo {
  static let shared = Geo()

  // https://www.movable-type.co.uk/scripts/latlong.html
  func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
    let dLon = to.longitude - from.longitude
    let y = sin(dLon) * cos(to.latitude)
    let x =
      cos(from.latitude) * sin(to.latitude) - sin(from.latitude) * cos(to.latitude) * cos(dLon)
    let brng = toDeg(rad: atan2(y, x))
    return 360 - ((brng + 360).truncatingRemainder(dividingBy: 360))
  }

  func toDeg(rad: Double) -> Double { return rad * 180 / Double.pi }
}
