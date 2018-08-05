//
//  Dummy.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 04/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class Dummy: TracksDelegate {
    static let shared = Dummy()
    
    func onTrack(_ track: TrackName) {
        
    }
}
