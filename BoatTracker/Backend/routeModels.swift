import Foundation
import MapboxMaps

struct RouteLink: Codable {
  let to: CLLocationCoordinate2D
  let cost: Distance
}

struct RouteSpec: Codable {
  let links: [RouteLink]
  let cost: Distance
}

struct RouteResult: Codable {
  let from: CLLocationCoordinate2D
  let to: CLLocationCoordinate2D
  let route: RouteSpec
  let totalCost: Distance
}
