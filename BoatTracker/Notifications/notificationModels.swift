//
//  models.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 11/10/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

struct PushToken: Equatable, Hashable, CustomStringConvertible, Codable {
    let token: String
    
    var description: String { return token }
}

enum BoatState: String, Codable {
    case connected
    case disconnected
}

struct BoatNotification: Codable {
    let boatName: BoatName
    let state: BoatState
}
