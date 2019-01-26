//
//  models.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

struct Vessel {
    static let heading = "heading"
    static let name = "name"
    let mmsi: Mmsi
    let name: String
    let heading: Double?
    let cog: Double
    let shipType: Int
    let draft: Distance
    let coord: CLLocationCoordinate2D
    let timestamp: Date
    let destination: String?
    
    static func parse(json: JsObject) throws -> Vessel {
        return Vessel(
            mmsi: Mmsi.from(number: try json.readUInt("mmsi")),
            name: try json.readString("name"),
            heading: try json.readOpt(Double.self, "heading"),
            cog: try json.readDouble("cog"),
            shipType: try json.readInt("shipType"),
            draft: try json.readDouble("draft").meters,
            coord: try json.coord("coord"),
            timestamp: try json.timestampMillis("timestampMillis"),
            destination: try json.readOpt(String.self, "destination")
        )
    }
    
    static func list(json: JsObject) throws -> [Vessel] {
        return try json.readObjectArray("vessels", each: parse)
    }
}

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
    let boatTimeMillis: UInt64
    let speed: Speed
    let depth: Distance
    let waterTemp: Temperature
    
    static func parse(json: JsObject) throws -> CoordBody {
        return CoordBody(
            coord: try json.coord("coord"),
            boatTime: try json.readString("boatTime"),
            boatTimeMillis: try json.readUInt("boatTimeMillis"),
            speed: Speed(knots: try json.readDouble("speed")),
            depth: (try json.readDouble("depth")).mm,
            waterTemp: (try json.readDouble("waterTemp")).celsius
        )
    }
 
    init(coord: CLLocationCoordinate2D, boatTime: String, boatTimeMillis: UInt64, speed: Speed, depth: Distance, waterTemp: Temperature) {
        self.coord = coord
        self.boatTime = boatTime
        self.boatTimeMillis = boatTimeMillis
        self.speed = speed
        self.depth = depth
        self.waterTemp = waterTemp
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
    let topPoint: CoordBody
    
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
            avgWaterTemp: (try json.readOpt(Double.self, "avgWaterTemp")).map { $0.celsius },
            topPoint: (try json.readObj("topPoint", parse: CoordBody.parse))
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

struct Mmsi: Equatable, Hashable, CustomStringConvertible {
    static let key = "mmsi"
    let mmsi: String
    var description: String { return mmsi }
    
    static func == (lhs: Mmsi, rhs: Mmsi) -> Bool { return lhs.mmsi == rhs.mmsi }
    
    static func from(number: UInt64) -> Mmsi { return Mmsi(mmsi: "\(number)") }
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

class Boat {
    let id: Int
    let name: BoatName
    let token: String
    let addedMillis: UInt64
    
    static func parse(json: JsObject) throws -> Boat {
        return Boat(id: try json.readInt("id"),
                    name: BoatName(name: try json.readString("name")),
                    token: try json.readString("token"),
                    addedMillis: try json.readUInt("addedMillis")
        )
    }
    
    init(id: Int, name: BoatName, token: String, addedMillis: UInt64) {
        self.id = id
        self.name = name
        self.token = token
        self.addedMillis = addedMillis
    }
}

struct UserToken {
    let email: String
    let token: AccessToken
}

struct SimpleMessage {
    let message: String
    
    static func parse(obj: JsObject) throws -> SimpleMessage {
        return SimpleMessage(message: try obj.readString("message"))
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
