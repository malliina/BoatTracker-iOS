//
//  Formats.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 02/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class Formats {
    static let shared = Formats()
    
    let formatter: DateFormatter
    let timestamper: DateFormatter
    
    init() {
        formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        timestamper = DateFormatter()
        timestamper.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    func format(date: Date) -> String {
        return formatter.string(from: date)
    }
    
    func timestamped(date: Date) -> String {
        return timestamper.string(from: date)
    }
}
