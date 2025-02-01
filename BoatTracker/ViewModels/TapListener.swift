import Foundation
import MapboxMaps

enum TapResult {
  case trophy(info: TrophyInfo, at: CLLocationCoordinate2D)
  case limit(area: LimitArea, at: CLLocationCoordinate2D)
  case miniMark(info: MinimalMarineSymbol, at: CLLocationCoordinate2D)
  case mark(info: MarineSymbol, point: CGPoint, at: CLLocationCoordinate2D)
  case boat(info: BoatPoint)
  case vessel(info: Vessel)
  case area(info: FairwayArea, limit: LimitArea?)
  case trail(info: TrackPoint)
  case trailPoint(info: SingleTrackPoint)
}

struct Tapped {
  let source: UIView
  let point: CGPoint
  let result: TapResult

  static func markCoordinate(_ feature: Feature) -> CLLocationCoordinate2D? {
    switch feature.geometry {
    case .point(let point): return point.coordinates
    default: return nil
    }
  }

  static func markResult(_ feature: Feature, point: CGPoint) -> TapResult? {
    guard let coordinate = markCoordinate(feature) else { return nil }
    let props = feature.properties ?? [:]
    let full: TapResult? = props.parseOpt(MarineSymbol.self).map { symbol in
      .mark(info: symbol, point: point, at: coordinate)
    }

    let minimal: TapResult? = props.parseOpt(MinimalMarineSymbol.self).map {
      symbol in
      .miniMark(info: symbol, at: coordinate)
    }
    return full ?? minimal
  }
}

extension JSONObject {
  func parse<T: Decodable>(_ t: T.Type) throws -> T {
    try Json.shared.parse(t, from: self)
  }
  func parseOpt<T: Decodable>(_ t: T.Type) -> T? {
    try? parse(t)
  }
}
