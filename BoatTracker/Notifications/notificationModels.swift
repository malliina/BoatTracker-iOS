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

enum BoatState {
    case connected
    case disconnected
    
    static func parse(input: String) throws -> BoatState {
        if input == "connected" { return connected }
        else if input == "disconnected" { return disconnected }
        else { throw JsonError.invalid("Unknown boat state: '\(input)'.", input) }
    }
}

struct BoatNotification {
    let boatName: BoatName
    let state: BoatState
    
    static func parse(obj: JsObject) throws -> BoatNotification {
        return BoatNotification(boatName: BoatName(name: try obj.readString("boatName")),
                                state: try BoatState.parse(input: try obj.readString("state"))
        )
    }
}
