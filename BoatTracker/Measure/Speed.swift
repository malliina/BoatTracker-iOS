import Foundation

public struct Speed: Comparable, CustomStringConvertible, DoubleCodable {
    static let knotInKmh: Double = 1.852
    static let zero = Speed(0)
    static let key = "speed"
    
    let knots: Double
    var kmh: Double { knots * Speed.knotInKmh }
    var value: Double { knots }
    var rounded: String { String(format: "%.2f", knots) }
    var roundedKmh: String { String(format: "%.0f", kmh) }
    
    public var description: String { formattedKnots }
    var formattedKmh: String { "\(roundedKmh) km/h" }
    var formattedKnots: String { "\(rounded) kn" }
    
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

public extension Double {
    var knots: Speed { Speed(self) }
    var kmh: Speed { Speed(self / Speed.knotInKmh) }
}

public extension Int {
    var knots: Speed { Double(self).knots }
    var kmh: Speed { Double(self).kmh }
}
