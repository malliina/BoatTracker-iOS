//
//  Distance.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

public struct Distance: Comparable {
    static let k = 1000
    static let zero = Distance(mm: 0)
    
    let mm: Int
    
    public static func == (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.mm == rhs.mm
    }
    
    public static func < (lhs: Distance, rhs: Distance) -> Bool {
        return lhs.mm < rhs.mm
    }
}

public extension Int {
    var mm: Distance { return Distance(mm: self) }
    var meters: Distance { return Distance(mm: self * Distance.k) }
    var kilometers: Distance { return Distance(mm: self * Distance.k * Distance.k) }
}

public extension Double {
    var mm: Distance { return Int(self).mm }
    var meters: Distance { return Int(self).meters }
    var kilometers: Distance { return Int(self).kilometers }
}
