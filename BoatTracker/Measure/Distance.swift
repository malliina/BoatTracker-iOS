import Foundation

public struct Distance: Comparable, CustomStringConvertible, DoubleCodable {
    static let k: Double = 1000.0
    static let zero = Distance(0.0)
    
    let meters: Double
    var value: Double { return meters }
    
    init(_ value: Double) {
        self.meters = value
    }
    
    init(meters: Double) {
        self.meters = meters
    }
    
    var kilometers: Double { return meters / 1000 }
    
    var rounded: String { return String(format: "%.2f", kilometers) }
    
    var formatKilometers: String { return String(format: "%.2f km", kilometers) }
    
    var formatMeters: String { return String(format: "%.1f m", meters) }
    
    public var description: String { return "\(rounded) km" }
    
    public static func == (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.meters == rhs.meters
    }
    
    public static func < (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.meters < rhs.meters
    }
}

public extension Int {
    var mm: Distance { return Distance(meters: 1.0 * Double(self) / Distance.k) }
    var meters: Distance { return Distance(meters: Double(self)) }
    var kilometers: Distance { return Distance(meters: Double(self) * Distance.k) }
}

public extension Double {
    var mm: Distance { return Distance(meters: self / Distance.k) }
    var meters: Distance { return Distance(meters: self) }
    var kilometers: Distance { return Distance(meters: self * Distance.k) }
}
