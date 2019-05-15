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
    var top: CoordBody
    
    init(top: CoordBody) {
        self.top = top
        self.title = top.speed.description
        self.subtitle = top.time.dateTime
        self.coordinate = top.coord
    }
    
    func update(top: CoordBody) {
        self.top = top
        self.title = top.speed.description
        self.subtitle = top.time.dateTime
        self.coordinate = top.coord
    }
}

class RouteAnnotation: NSObject, MGLAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var isEnd: Bool
    
    init(at: CLLocationCoordinate2D, isEnd: Bool) {
        self.title = "t"
        self.subtitle = "s"
        self.coordinate = at
        self.isEnd = isEnd
    }
}

class CustomAnnotation: NSObject, MGLAnnotation {
    // Insane hack: the MGLAnnotation object requires a title property, otherwise the callout is never shown.
    // Best source I could find is https://github.com/mapbox/react-native-mapbox-gl/issues/1278.
    var title: String? = ""
    var coordinate: CLLocationCoordinate2D
    
    init(coord: CLLocationCoordinate2D) {
        // The title value must also be defined
        self.title = ""
        self.coordinate = coord
    }
}
