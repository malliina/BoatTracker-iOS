import Foundation

public struct Power: Comparable, CustomStringConvertible, DoubleCodable, Hashable {
  static let zero = Power(watts: 0)

  let watts: Double
  var value: Double { watts }

  init(_ watts: Double) {
    self.init(watts: watts)
  }

  init(watts: Double) {
    self.watts = watts
  }

  public var description: String { String(format: "%.1f kW", watts/1000) }

  public static func == (lhs: Power, rhs: Power) -> Bool {
    lhs.watts == rhs.watts
  }

  public static func < (lhs: Power, rhs: Power) -> Bool {
    lhs.watts < rhs.watts
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}

extension Int {
  public var watts: Power { Power(watts: Double(self)) }
}

extension Double {
  public var watts: Power { Power(watts: Double(self)) }
}
