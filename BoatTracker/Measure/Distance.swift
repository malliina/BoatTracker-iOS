//
//  Distance.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

struct Distance: Comparable, CustomStringConvertible, DoubleCodable {
    static let k = 1000
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
    
    var formatMeters: String { return String(format: "%.1f m", meters) }
    
    public var description: String { return "\(rounded) km" }
    
    public static func == (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.meters == rhs.meters
    }
    
    public static func < (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.meters < rhs.meters
    }
}

public struct DistanceMillis: Comparable, CustomStringConvertible, NormalIntCodable {
    static let k = 1000
    static let zero = DistanceMillis(mm: 0)
    
    let mm: Int
    var value: Int { return mm }
    
    init(_ value: Int) {
        self.mm = value
    }
    
    init(mm: Int) {
        self.mm = mm
    }
    
    var meters: Double { return Double(mm) / 1000 }
    
    var kilometers: Double { return Double(mm) / 1000 / 1000 }
    
    var rounded: String { return String(format: "%.2f", kilometers) }
    
    var formatMeters: String { return String(format: "%.1f m", meters) }
    
    public var description: String { return "\(rounded) km" }
    
    public static func == (lhs: DistanceMillis, rhs: DistanceMillis) -> Bool {
        return lhs.mm == rhs.mm
    }
    
    public static func < (lhs: DistanceMillis, rhs: DistanceMillis) -> Bool {
        return lhs.mm < rhs.mm
    }
}

public extension Int {
    var mm: DistanceMillis { return DistanceMillis(mm: self) }
    var meters: DistanceMillis { return DistanceMillis(mm: self * DistanceMillis.k) }
    var kilometers: DistanceMillis { return DistanceMillis(mm: self * DistanceMillis.k * DistanceMillis.k) }
}

public extension Double {
    var mm: DistanceMillis { return Int(self).mm }
    var meters: DistanceMillis { return Int(self).meters }
    var kilometers: DistanceMillis { return Int(self).kilometers }
}
