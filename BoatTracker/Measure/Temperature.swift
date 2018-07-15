//
//  Temperature.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Temperature: Comparable, CustomStringConvertible {
    static func fahrenheitToCelsius(f: Double) -> Double {
        return (f - 32) * 5 / 9
    }
    
    static func kelvinToCelsius(k: Double) -> Double {
        return k + 273.15
    }
    
    static let zero = Temperature(celsius: 0)
    
    let celsius: Double
    
    public var description: String { return "\(celsius) ℃" }
    
    public static func == (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius == rhs.celsius
    }
    
    public static func < (lhs: Temperature, rhs: Temperature) -> Bool {
        return lhs.celsius < rhs.celsius
    }
}

public extension Double {
    var celsius: Temperature { return Temperature(celsius: self) }
    var fahrenheit: Temperature { return Temperature(celsius: Temperature.fahrenheitToCelsius(f: self)) }
    var kelvin: Temperature { return Temperature(celsius: Temperature.kelvinToCelsius(k: self)) }
}

public extension Int {
    var celsius: Temperature { return Double(self).celsius }
    var fahrenheit: Temperature { return Double(self).fahrenheit }
    var kelvin: Temperature { return Double(self).kelvin }
}
