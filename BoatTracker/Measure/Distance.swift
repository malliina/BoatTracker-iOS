import Foundation

public struct Distance: Comparable, CustomStringConvertible, DoubleCodable, Hashable {
  static let k: Double = 1000.0
  static let zero = Distance(0.0)

  let meters: Double
  var value: Double { meters }

  init(_ value: Double) {
    self.meters = value
  }

  init(meters: Double) {
    self.meters = meters
  }

  var kilometers: Double { meters / 1000 }

  var rounded: String { String(format: "%.2f", kilometers) }

  var formatKilometers: String { String(format: "%.2f km", kilometers) }

  var formatMeters: String { String(format: "%.1f m", meters) }

  public var description: String { "\(rounded) km" }

  public static func == (lhs: Distance, rhs: Distance) -> Bool {
    lhs.meters == rhs.meters
  }

  public static func < (lhs: Distance, rhs: Distance) -> Bool {
    lhs.meters < rhs.meters
  }
}

extension Int {
  public var mm: Distance { Distance(meters: 1.0 * Double(self) / Distance.k) }
  public var meters: Distance { Distance(meters: Double(self)) }
  public var kilometers: Distance { Distance(meters: Double(self) * Distance.k) }
}

extension Double {
  public var mm: Distance { Distance(meters: self / Distance.k) }
  public var meters: Distance { Distance(meters: self) }
  public var kilometers: Distance { Distance(meters: self * Distance.k) }
}
