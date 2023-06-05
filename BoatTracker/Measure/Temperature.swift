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
    
    var value: Double { return celsius }
    
    public init(_ celsius: Double) {
        self.celsius = celsius
    }
    
    var rounded: String { return String(format: "%.2f", celsius) }
    
    public var description: String { return "\(rounded) ℃" }
    
    public static func == (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius == rhs.celsius
    }
    
    public static func < (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius < rhs.celsius
    }
}

public extension Double {
    var celsius: Temperature { return Temperature(self) }
    var fahrenheit: Temperature { return Temperature(Temperature.fahrenheitToCelsius(f: self)) }
    var kelvin: Temperature { return Temperature(Temperature.kelvinToCelsius(k: self)) }
}

public extension Int {
    var celsius: Temperature { return Double(self).celsius }
    var fahrenheit: Temperature { return Double(self).fahrenheit }
    var kelvin: Temperature { return Double(self).kelvin }
}
