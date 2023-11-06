import Foundation

public struct Temperature: Comparable, CustomStringConvertible, DoubleCodable {
  static func fahrenheitToCelsius(f: Double) -> Double {
    return (f - 32) * 5 / 9
  }

  static func kelvinToCelsius(k: Double) -> Double {
    return k + 273.15
  }

  static let zero = Temperature(0)

  let celsius: Double

  var value: Double { celsius }

  public init(_ celsius: Double) {
    self.celsius = celsius
  }

  var rounded: String { String(format: "%.2f", celsius) }

  var formatCelsius: String { "\(rounded) ℃" }
  public var description: String { formatCelsius }

  public static func == (lhs: Temperature, rhs: Temperature) -> Bool {
    return lhs.celsius == rhs.celsius
  }

  public static func < (lhs: Temperature, rhs: Temperature) -> Bool {
    return lhs.celsius < rhs.celsius
  }
}

extension Double {
  public var celsius: Temperature { Temperature(self) }
  public var fahrenheit: Temperature { Temperature(Temperature.fahrenheitToCelsius(f: self)) }
  public var kelvin: Temperature { Temperature(Temperature.kelvinToCelsius(k: self)) }
}

extension Int {
  public var celsius: Temperature { Double(self).celsius }
  public var fahrenheit: Temperature { Double(self).fahrenheit }
  public var kelvin: Temperature { Double(self).kelvin }
}
