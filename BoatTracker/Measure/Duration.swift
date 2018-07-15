//
//  Duration.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Duration: Comparable, CustomStringConvertible {
    static let k = 1000
    static let zero = Duration(ms: 0)
    
    let ms: UInt64
    
    var seconds: Double { return Double(ms) / Double(Duration.k) }
    
    public var description: String { return "\(seconds) s" }
    
    public static func == (lhs: Duration, rhs: Duration) -> Bool {
        return lhs.ms == rhs.ms
    }
    
    public static func < (lhs: Duration, rhs: Duration) -> Bool {
        return lhs.ms < rhs.ms
    }
}

public extension Int {
    var ms: Duration { return Duration(ms: UInt64(self)) }
    var seconds: Duration { return Duration(ms: UInt64(self * Duration.k)) }
}

public extension Double {
    var ms: Duration { return Duration(ms: UInt64(self)) }
    var seconds: Duration { return Duration(ms: UInt64(self * Double(Duration.k))) }
}
