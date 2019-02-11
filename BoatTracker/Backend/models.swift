//
//  models.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

enum AidType {
    case unknown
    case lighthouse
    case sectorLight
    case leadingMark
    case directionalLight
    case minorLight
    case otherMark
    case edgeMark
    case radarTarget
    case buoy
    case beacon
    case signatureLighthouse
    case cairn
    
    func translate(lang: AidTypeLang) -> String {
        switch self {
        case .lighthouse: return lang.lighthouse
        case .sectorLight: return lang.sectorLight
        case .leadingMark: return lang.leadingMark
        case .directionalLight: return lang.directionalLight
        case .minorLight: return lang.minorLight
        case .otherMark: return lang.otherMark
        case .edgeMark: return lang.edgeMark
        case .radarTarget: return lang.radarTarget
        case .buoy: return lang.buoy
        case .beacon: return lang.beacon
        case .signatureLighthouse: return lang.signatureLighthouse
        case .cairn: return lang.cairn
        case .unknown: return lang.unknown
        }
    }
    
    static func parse(code: Int) throws -> AidType {
        switch code {
        case 0: return .unknown
        case 1: return .lighthouse
        case 2: return .sectorLight
        case 3: return .leadingMark
        case 4: return .directionalLight
        case 5: return .minorLight
        case 6: return .otherMark
        case 7: return .edgeMark
        case 8: return .radarTarget
        case 9: return .buoy
        case 10: return .beacon
        case 11: return .signatureLighthouse
        case 13: return .cairn
        default: throw JsonError.invalid("Unknown aid type: '\(code)'.", code)
        }
    }
}

enum NavMark {
    case unknown
    case left
    case right
    case north
    case south
    case west
    case east
    case rock
    case safeWaters
    case special
    case notApplicable
    
    func translate(lang: NavMarkLang) -> String {
        switch self {
        case .left: return lang.left
        case .right: return lang.right
        case .north: return lang.north
        case .south: return lang.south
        case .west: return lang.unknown
        case .east: return lang.east
        case .rock: return lang.rock
        case .safeWaters: return lang.safeWaters
        case .special: return lang.special
        case .notApplicable: return lang.notApplicable
        case .unknown: return lang.unknown
        }
    }
    
    static func parse(code: Int) throws -> NavMark {
        switch code {
        case 0: return .unknown
        case 1: return .left
        case 2: return .right
        case 3: return .north
        case 4: return .south
        case 5: return .west
        case 6: return .east
        case 7: return .rock
        case 8: return .safeWaters
        case 9: return .special
        case 99: return .notApplicable
        default: throw JsonError.invalid("Unknown mark type: '\(code)'.", code)
        }
    }
}

enum ConstructionInfo {
    case buoyBeacon
    case iceBuoy
    case beaconBuoy
    case superBeacon
    case exteriorLight
    case dayBoard
    case helicopterPlatform
    case radioMast
    case waterTower
    case smokePipe
    case radarTower
    case churchTower
    case superBuoy
    case edgeCairn
    case compassCheck
    case borderMark
    case borderLineMark
    case channelEdgeLight
    case tower
    
    func translate(lang: ConstructionLang) -> String {
        switch self {
        case .buoyBeacon: return lang.buoyBeacon
        case .iceBuoy: return lang.iceBuoy
        case .beaconBuoy: return lang.beaconBuoy
        case .superBeacon: return lang.superBeacon
        case .exteriorLight: return lang.exteriorLight
        case .dayBoard: return lang.dayBoard
        case .helicopterPlatform: return lang.helicopterPlatform
        case .radioMast: return lang.radioMast
        case .waterTower: return lang.waterTower
        case .smokePipe: return lang.smokePipe
        case .radarTower: return lang.radarTower
        case .churchTower: return lang.churchTower
        case .superBuoy: return lang.superBuoy
        case .edgeCairn: return lang.edgeCairn
        case .compassCheck: return lang.compassCheck
        case .borderMark: return lang.borderMark
        case .borderLineMark: return lang.borderLineMark
        case .channelEdgeLight: return lang.channelEdgeLight
        case .tower: return lang.tower
        }
    }
    
    static func parse(code: Int) throws -> ConstructionInfo {
        switch code {
        case 1: return .buoyBeacon
        case 2: return .iceBuoy
        case 4: return .beaconBuoy
        case 5: return .superBeacon
        case 6: return .exteriorLight
        case 7: return .dayBoard
        case 8: return .helicopterPlatform
        case 9: return .radioMast
        case 10: return .waterTower
        case 11: return .smokePipe
        case 12: return .radarTower
        case 13: return .churchTower
        case 14: return .superBuoy
        case 15: return .edgeCairn
        case 16: return .compassCheck
        case 17: return .borderMark
        case 18: return .borderLineMark
        case 19: return .channelEdgeLight
        case 20: return .tower
        default: throw JsonError.invalid("Unknown construction type: '\(code)'.", code)
        }
    }
}

enum Flotation {
    case floating
    case solid
    case other(name: String)
    
    static func parse(input: String) -> Flotation {
        switch input {
        case "KELLUVA": return .floating
        case "KIINTE": return .solid
        default: return .other(name: input)
        }
    }
}

class MarineSymbol: NSObject {
    let owner: String
    let exteriorLight: Bool
    let topSign: Bool
    let nameFi: String?
    let nameSe: String?
    let locationFi: String?
    let locationSe: String?
    let flotation: Flotation
    let state: String
    let lit: Bool
    let aidType: AidType
    let navMark: NavMark
    let construction: ConstructionInfo?
    
    var hasLocation: Bool { return locationFi != nil || locationSe != nil }
    
    func location(lang: Language) -> String? {
        switch lang {
        case .fi: return locationFi ?? locationSe
        case .se: return locationSe ?? locationFi
        case .en: return locationFi ?? locationSe
        }
    }
    
    func name(lang: Language) -> String? {
        switch lang {
        case .fi: return nameFi ?? nameSe
        case .se: return nameSe ?? nameFi
        case .en: return nameFi ?? nameSe
        }
    }
    
    func translatedOwner(finnish: SpecialWords, translated: SpecialWords) -> String {
        switch owner {
        case finnish.transportAgency: return translated.transportAgency
        case finnish.defenceForces: return translated.defenceForces
        case finnish.portOfHelsinki: return translated.portOfHelsinki
        case finnish.cityOfEspoo: return translated.cityOfEspoo
        default: return owner
        }
    }
    
    init(owner: String, exteriorLight: Bool, topSign: Bool, nameFi: String?, nameSe: String?, locationFi: String?, locationSe: String?, flotation: Flotation, state: String, lit: Bool, aidType: AidType, navMark: NavMark, construction: ConstructionInfo?) {
        self.owner = owner
        self.exteriorLight = exteriorLight
        self.topSign = topSign
        self.nameFi = nameFi
        self.nameSe = nameSe
        self.locationFi = locationFi
        self.locationSe = locationSe
        self.flotation = flotation
        self.state = state
        self.lit = lit
        self.aidType = aidType
        self.navMark = navMark
        self.construction = construction
    }
    
    static func boolNum(i: Int) throws -> Bool {
        switch i {
        case 0: return false
        case 1: return true
        default: throw JsonError.invalid("Unexpected integer, must be 1 or 0: '\(i)'.", i)
        }
    }
    
    static func boolString(s: String) throws -> Bool {
        switch s {
        case "K": return true
        case "E": return false
        default: throw JsonError.invalid("Unexpected string, must be K or E: '\(s)'.", s)
        }
    }
    
    static func parse(json: JsObject) throws -> MarineSymbol {
        return MarineSymbol(
            owner: try json.readString("OMISTAJA"),
            exteriorLight: try boolNum(i: try json.readInt("FASADIVALO")),
            topSign: try boolNum(i: try json.readInt("HUIPPUMERK")),
            nameFi: try json.nonEmptyString("NIMIS"),
            nameSe: try json.nonEmptyString("NIMIR"),
            locationFi: try json.nonEmptyString("SIJAINTIS"),
            locationSe: try json.nonEmptyString("SIJAINTIR"),
            flotation: Flotation.parse(input: try json.readString("SUBTYPE")),
            state: try json.readString("TILA"),
            lit: try boolString(s: try json.readString("VALAISTU")),
            aidType: try AidType.parse(code: try json.readInt("TY_JNR")),
            navMark: try NavMark.parse(code: try json.readInt("NAVL_TYYP")),
            construction: try json.readOpt(Int.self, "RAKT_TYYP").map { i in try ConstructionInfo.parse(code: i) }
        )
    }
}

class Vessel: NSObject {
    static let heading = "heading"
    static let name = "name"
    
    let mmsi: Mmsi
    let name: String
    let heading: Double?
    let cog: Double
    let speed: Speed
    let shipType: Int
    let draft: Distance
    let coord: CLLocationCoordinate2D
    let timestamp: Date
    let destination: String?
    
    init(mmsi: Mmsi, name: String, heading: Double?, cog: Double, speed: Speed, shipType: Int, draft: Distance, coord: CLLocationCoordinate2D, timestamp: Date, destination: String?) {
        self.mmsi = mmsi
        self.name = name
        self.heading = heading
        self.cog = cog
        self.speed = speed
        self.shipType = shipType
        self.draft = draft
        self.coord = coord
        self.timestamp = timestamp
        self.destination = destination
    }
    
    static func parse(json: JsObject) throws -> Vessel {
        return Vessel(
            mmsi: Mmsi.from(number: try json.readUInt("mmsi")),
            name: try json.readString("name"),
            heading: try json.readOpt(Double.self, "heading"),
            cog: try json.readDouble("cog"),
            speed: try json.readDouble("sog").knots,
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

class CoordBody: NSObject {
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
            speed: (try json.readDouble("speed")).knots,
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

enum Language {
    case fi
    case se
    case en
    
    static func parse(s: String) -> Language {
        switch s {
        case "fi": return fi
        case "se": return se
        case "en": return en
        default: return en
        }
    }
}

class UserProfile {
    let id: Int
    let username: Username
    let email: String?
    let language: Language
    let boats: [Boat]
    let addedMillis: UInt64

    static func parse(obj: JsObject) throws -> UserProfile {
        return try parseUser(obj: try obj.readObject("user"))
    }
    
    static func parseUser(obj: JsObject) throws -> UserProfile {
        return UserProfile(id: try obj.readInt("id"),
                           username: Username(name: try obj.readString("username")),
                           email: try obj.readOpt(String.self, "email"),
                           language: Language.parse(s: try obj.readString("language")),
                           boats: try obj.readObjectArray("boats", each: Boat.parse),
                           addedMillis: try obj.readUInt("addedMillis")
        )
    }
    
    init(id: Int, username: Username, email: String?, language: Language, boats: [Boat], addedMillis: UInt64) {
        self.id = id
        self.username = username
        self.email = email
        self.language = language
        self.boats = boats
        self.addedMillis = addedMillis
    }
}
