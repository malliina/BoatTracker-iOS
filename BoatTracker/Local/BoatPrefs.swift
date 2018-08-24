//
//  BoatPrefs.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 24/08/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class BoatPrefs {
    static let shared = BoatPrefs()
    let prefs = UserDefaults.standard
    
    let welcomeKey = "welcome"
    
    var isWelcomeRead: Bool {
        get { return prefs.bool(forKey: welcomeKey) }
        set (newValue) { prefs.set(newValue, forKey: welcomeKey) }
    }
}
