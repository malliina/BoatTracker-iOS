//
//  models.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/10/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class PushToken {
    let token: String
    
    init(token: String) {
        self.token = token
    }
}

enum BoatState: String, Codable {
    case connected
    case disconnected
}

struct BoatNotification: Codable {
    let boatName: BoatName
    let state: BoatState
}
