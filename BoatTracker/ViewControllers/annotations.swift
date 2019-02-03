//
//  annotations.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

class TrophyAnnotation: NSObject, MGLAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(top: CoordBody) {
        self.title = top.speed.description
        self.subtitle = top.boatTime
        self.coordinate = top.coord
    }
    
    func update(top: CoordBody) {
        self.title = top.speed.description
        self.subtitle = top.boatTime
        self.coordinate = top.coord
    }
}

// The annotation may be updated on the go while it's added to the map, therefore the model is mutable (and also to comply with MGLAnnotation)
class VesselAnnotation: NSObject, MGLAnnotation {
    // Insane hack: the MGLAnnotation object requires a title property, otherwise the callout is never shown.
    // Best source I could find is https://github.com/mapbox/react-native-mapbox-gl/issues/1278.
    var title: String?
    
    var name: String
    var destination: String?
    var speed: Speed
    var draft: Distance
    var boatTime: Date
    var coordinate: CLLocationCoordinate2D
    
    init(vessel: Vessel) {
        // The title value must also be defined
        self.title = ""
        
        self.name = vessel.name
        self.destination = vessel.destination
        self.speed = vessel.speed
        self.draft = vessel.draft
        self.boatTime = vessel.timestamp
        self.coordinate = vessel.coord
    }
    
    func update(with vessel: Vessel) {
        self.name = vessel.name
        self.destination = vessel.destination
        self.speed = vessel.speed
        self.draft = vessel.draft
        self.boatTime = vessel.timestamp
        self.coordinate = vessel.coord
    }
    
}
