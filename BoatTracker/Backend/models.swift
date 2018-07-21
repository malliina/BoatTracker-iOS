//
//  models.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

class CoordsData {
    let coords: [CoordBody]
    let from: TrackRef
    
    static func parse(json: JsObject) throws -> CoordsData {
        let body = try json.readObject("body")
        let from = try body.readObj("from", parse: { (f) -> TrackRef in
            try TrackRef.parse(json: f)
        })
        let coords = try body.readObjectArray("coords", each: { (c) -> CoordBody in
            try CoordBody.parse(json: c)
        })
        return CoordsData(coords: coords, from: from)
    }
    
    init(coords: [CoordBody], from: TrackRef) {
        self.coords = coords
        self.from = from
    }
}

class CoordBody {
    let coord: CLLocationCoordinate2D
    let boatTime: String
    let speed: Speed
    
    static func parse(json: JsObject) throws -> CoordBody {
        let c = try json.readObject("coord")
        return CoordBody(
            coord: CLLocationCoordinate2D(latitude: try c.readDouble("lat"), longitude: try c.readDouble("lng")),
            boatTime: try json.readString("boatTime"),
            speed: Speed(knots: try json.readDouble("speed"))
        )
    }
 
    init(coord: CLLocationCoordinate2D, boatTime: String, speed: Speed) {
        self.coord = coord
        self.boatTime = boatTime
        self.speed = speed
    }
}

class TrackRef {
    let trackName: TrackName
    let boatName: BoatName
    let username: Username
    
    let topSpeed: Speed?
    let avgSpeed: Speed?
    let distance: Distance
    let duration: Duration
    let avgWaterTemp: Temperature?

    static func parse(json: JsObject) throws -> TrackRef {
        return TrackRef(
            trackName: TrackName(name: try json.readString("trackName")),
            boatName: BoatName(name: try json.readString("boatName")),
            username: Username(name: try json.readString("username")),
            topSpeed: (try json.readOpt(Double.self, "topSpeed")).map { $0.knots },
            avgSpeed: (try json.readOpt(Double.self, "avgSpeed")).map { $0.knots },
            distance: (try json.readDouble("distance")).mm,
            duration: (try json.readInt("duration")).seconds,
            avgWaterTemp: (try json.readOpt(Double.self, "avgWaterTemp")).map { $0.celsius }
        )
    }
    
    init(trackName: TrackName, boatName: BoatName, username: Username, topSpeed: Speed?, avgSpeed: Speed?, distance: Distance, duration: Duration, avgWaterTemp: Temperature?) {
        self.trackName = trackName
        self.boatName = boatName
        self.username = username
        self.topSpeed = topSpeed
        self.avgSpeed = avgSpeed
        self.distance = distance
        self.duration = duration
        self.avgWaterTemp = avgWaterTemp
    }
}

class TrackStats {
    let points: Int
    
    static func parse(json: JsObject) throws -> TrackStats {
        return TrackStats(points: try json.readInt("points"))
    }
    
    init(points: Int) {
        self.points = points
    }
}

struct AccessToken: Equatable, Hashable, CustomStringConvertible {
    let token: String
    var description: String { return token }
    
    static func == (lhs: AccessToken, rhs: AccessToken) -> Bool { return lhs.token == rhs.token }
}

struct BoatName: Equatable, Hashable, CustomStringConvertible {
    let name: String
    var description: String { return name }
    
    static func == (lhs: BoatName, rhs: BoatName) -> Bool { return lhs.name == rhs.name }
    
}

struct TrackName: Equatable, Hashable, CustomStringConvertible {
    let name: String
    var description: String { return name }
    
    static func == (lhs: TrackName, rhs: TrackName) -> Bool { return lhs.name == rhs.name }
}

struct Username: Equatable, Hashable, CustomStringConvertible {
    let name: String
    var description: String { return name }
    
    static func == (lhs: Username, rhs: Username) -> Bool { return lhs.name == rhs.name }
}
