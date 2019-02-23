//
//  Duration.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Duration: Comparable, CustomStringConvertible, DoubleCodable {
    static let k: Double = 1000.0
    static let zero = Duration(seconds: 0)
    
    let seconds: Double
    var value: Double { return seconds }
    
    init(_ seconds: Double) {
        self.init(seconds: seconds)
    }
    
    init(seconds: Double) {
        self.seconds = seconds
    }
    
    public var description: String { return Formatting.shared.format(duration: self) }
    
    public static func == (lhs: Duration, rhs: Duration) -> Bool {
        return lhs.seconds == rhs.seconds
    }
    
    public static func < (lhs: Duration, rhs: Duration) -> Bool {
        return lhs.seconds < rhs.seconds
    }
}

public extension Int {
    var ms: Duration { return Duration(seconds: Double(self) / Duration.k) }
    var seconds: Duration { return Duration(seconds: Double(self)) }
}

public extension Double {
    var ms: Duration { return Duration(seconds: Double(self) / Duration.k) }
    var seconds: Duration { return Duration(seconds: Double(self)) }
}
