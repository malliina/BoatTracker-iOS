//
//  Speed.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Speed: Comparable, CustomStringConvertible {
    static let knotInKmh: Double = 1.852
    static let zero = Speed(knots: 0)
    
    let knots: Double
    
    var rounded: String { return String(format: "%.2f", knots) }
    
    public var description: String { return " \(rounded) kn" }
    
    public static func == (lhs: Speed, rhs: Speed) -> Bool {
        return lhs.knots == rhs.knots
    }
    
    public static func < (lhs: Speed, rhs: Speed) -> Bool {
        return lhs.knots < rhs.knots
    }
}

public extension Double {
    var knots: Speed { return Speed(knots: self) }
    var kmh: Speed { return Speed(knots: Speed.knotInKmh * self) }
}

public extension Int {
    var knots: Speed { return Double(self).knots }
    var kmh: Speed { return Double(self).kmh }
}
