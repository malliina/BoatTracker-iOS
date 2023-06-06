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
    
    public var description: String { "\(rounded) ℃" }
    
    public static func == (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius == rhs.celsius
    }
    
    public static func < (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius < rhs.celsius
    }
}

public extension Double {
    var celsius: Temperature { Temperature(self) }
    var fahrenheit: Temperature { Temperature(Temperature.fahrenheitToCelsius(f: self)) }
    var kelvin: Temperature { Temperature(Temperature.kelvinToCelsius(k: self)) }
}

public extension Int {
    var celsius: Temperature { Double(self).celsius }
    var fahrenheit: Temperature { Double(self).fahrenheit }
    var kelvin: Temperature { Double(self).kelvin }
}
