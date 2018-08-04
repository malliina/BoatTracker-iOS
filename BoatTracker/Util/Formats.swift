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
    
    init() {
        formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
    }
    
    func format(date: Date) -> String {
        return formatter.string(from: date)
    }
}
