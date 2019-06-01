//
//  Speed.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Speed: Comparable, CustomStringConvertible, DoubleCodable {
    static let knotInKmh: Double = 1.852
    static let zero = Speed(0)
    
    let knots: Double
    var kmh: Double { return knots * Speed.knotInKmh }
    var value: Double { return knots }
    var rounded: String { return String(format: "%.2f", knots) }
    var roundedKmh: String { return String(format: "%.0f", kmh) }
    
    public var description: String { return "\(rounded) kn" }
    var formattedKmh: String { return "\(roundedKmh) km/h" }
    
    init(_ knots: Double) {
        self.knots = knots
    }
    
    public static func == (lhs: Speed, rhs: Speed) -> Bool {
        return lhs.knots == rhs.knots
    }
    
    public static func < (lhs: Speed, rhs: Speed) -> Bool {
        return lhs.knots < rhs.knots
    }
}

public extension Double {
    var knots: Speed { return Speed(self) }
    var kmh: Speed { return Speed(self / Speed.knotInKmh) }
}

public extension Int {
    var knots: Speed { return Double(self).knots }
    var kmh: Speed { return Double(self).kmh }
}
