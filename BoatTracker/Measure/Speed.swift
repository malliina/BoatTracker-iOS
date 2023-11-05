import Foundation

public struct Speed: Comparable, DoubleCodable {
  static let knotInKph: Double = 1.852
  static let zero = Speed(0)
  static let key = "speed"

  let knots: Double
  var kph: Double { knots * Speed.knotInKph }
  var value: Double { knots }
  var rounded: String { String(format: "%.2f", knots) }
  var roundedKph: String { String(format: "%.0f", kph) }

  //    public var description: String { formattedKnots }
  var formattedKph: String { "\(roundedKph) km/h" }
  var formattedKnots: String { "\(rounded) kn" }
  func formatted(isBoat: Bool) -> String { isBoat ? formattedKnots : formattedKph }

  init(_ knots: Double) {
    self.knots = knots
  }

  public static func == (lhs: Speed, rhs: Speed) -> Bool {
    lhs.knots == rhs.knots
  }

  public static func < (lhs: Speed, rhs: Speed) -> Bool {
    lhs.knots < rhs.knots
  }
}

extension Double {
  public var knots: Speed { Speed(self) }
  public var kmh: Speed { Speed(self / Speed.knotInKph) }
}

extension Int {
  public var knots: Speed { Double(self).knots }
  public var kmh: Speed { Double(self).kmh }
}
