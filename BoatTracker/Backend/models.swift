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
    let from: TrackMeta
    
    static func parse(json: JsObject) throws -> CoordsData {
        let body = try json.readObject("body")
        let from = try body.readObj("from", parse: { (f) -> TrackMeta in
            try TrackMeta.parse(json: f)
        })
        let coords = try body.readObjectArray("coords", each: { (c) -> CoordBody in
            try CoordBody.parse(json: c)
        })
        return CoordsData(coords: coords, from: from)
    }
    
    init(coords: [CoordBody], from: TrackMeta) {
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

struct TrackMeta {
    let trackName: TrackName
    let boatName: BoatName
    let username: Username
    
    static func parse(json: JsObject) throws -> TrackMeta {
        return TrackMeta(
            trackName: TrackName(name: try json.readString("trackName")),
            boatName: BoatName(name: try json.readString("boatName")),
            username: Username(name: try json.readString("username"))
        )
    }
}

struct TrackRef {
    let trackName: TrackName
    let boatName: BoatName
    let username: Username
    
    let start: Date
    let topSpeed: Speed?
    let avgSpeed: Speed?
    let distance: Distance
    let duration: Duration
    let avgWaterTemp: Temperature?
    
    var startDate: String { get { return Formats.shared.format(date: start) } }

    static func parse(json: JsObject) throws -> TrackRef {
        return TrackRef(
            trackName: TrackName(name: try json.readString("trackName")),
            boatName: BoatName(name: try json.readString("boatName")),
            username: Username(name: try json.readString("username")),
            start: Date(timeIntervalSince1970: try json.readDouble("startMillis") / 1000),
            topSpeed: (try json.readOpt(Double.self, "topSpeed")).map { $0.knots },
            avgSpeed: (try json.readOpt(Double.self, "avgSpeed")).map { $0.knots },
            distance: (try json.readDouble("distance")).mm,
            duration: (try json.readInt("duration")).seconds,
            avgWaterTemp: (try json.readOpt(Double.self, "avgWaterTemp")).map { $0.celsius }
        )
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

class BackendInfo {
    let name: String
    let version: String
    
    static func parse(obj: JsObject) throws -> BackendInfo {
        return BackendInfo(name: try obj.readString("name"), version: try obj.readString("version"))
    }
    
    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
}

class TrackSummary {
    let track: TrackRef
    let stats: TrackStats
    
    static func parse(json: JsObject) throws -> TrackSummary {
        return TrackSummary(track: try json.readObj("track", parse: TrackRef.parse), stats: try json.readObj("stats", parse: TrackStats.parse))
    }
    
    init(track: TrackRef, stats: TrackStats) {
        self.track = track
        self.stats = stats
    }
}

class Boat {
    let id: Int
    let name: String
    let token: String
    let addedMillis: UInt64
    
    static func parse(json: JsObject) throws -> Boat {
        return Boat(id: try json.readInt("id"),
                    name: try json.readString("name"),
                    token: try json.readString("token"),
                    addedMillis: try json.readUInt("addedMillis"))
    }
    
    init(id: Int, name: String, token: String, addedMillis: UInt64) {
        self.id = id
        self.name = name
        self.token = token
        self.addedMillis = addedMillis
    }
}

class UserProfile {
    let id: Int
    let username: Username
    let email: String?
    let boats: [Boat]
    let addedMillis: UInt64
    
    static func parse(obj: JsObject) throws -> UserProfile {
        return try parseUser(obj: try obj.readObject("user"))
    }
    
    static func parseUser(obj: JsObject) throws -> UserProfile {
        return UserProfile(id: try obj.readInt("id"),
                           username: Username(name: try obj.readString("username")),
                           email: try obj.readOpt(String.self, "email"),
                           boats: try obj.readObjectArray("boats", each: Boat.parse),
                           addedMillis: try obj.readUInt("addedMillis")
        )
    }
    
    init(id: Int, username: Username, email: String?, boats: [Boat], addedMillis: UInt64) {
        self.id = id
        self.username = username
        self.email = email
        self.boats = boats
        self.addedMillis = addedMillis
    }
}
