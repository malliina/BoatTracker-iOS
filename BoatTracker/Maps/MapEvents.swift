//
//  MapDelegate.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 15/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

protocol MapDelegate {
    func close()
}

class MapEvents {
    static let shared = MapEvents()
    
    var delegate: MapDelegate? = nil
    
    func close() {
        delegate?.close()
    }
}
