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

struct Vessels {
    let vessels: [Vessel]
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
    let draft: DistanceMillis
    let coord: CLLocationCoordinate2D
    let timestampMillis: Double
    let destination: String?

    var timestamp: Date { return Date(timeIntervalSince1970: timestampMillis / 1000) }
    
    init(mmsi: Mmsi, name: String, heading: Double?, cog: Double, speed: Speed, shipType: Int, draft: DistanceMillis, coord: CLLocationCoordinate2D, timestampMillis: Double, destination: String?) {
        self.mmsi = mmsi
        self.name = name
        self.heading = heading
        self.cog = cog
        self.speed = speed
        self.shipType = shipType
        self.draft = draft
        self.coord = coord
        self.timestampMillis = timestampMillis
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
            timestampMillis: try json.readDouble("timestampMillis"),
            destination: try json.readOpt(String.self, "destination")
        )
    }
    
    static func list(json: JsObject) throws -> [Vessel] {
        return try json.readObjectArray("vessels", each: parse)
    }
}

extension CLLocationCoordinate2D: Codable {
    private enum CodingKeys: CodingKey {
        case lng
        case lat
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lng = try container.decode(Double.self, forKey: .lng)
        let lat = try container.decode(Double.self, forKey: .lat)
        self.init(latitude: lat, longitude: lng)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .lat)
        try container.encode(longitude, forKey: .lng)
    }
}

struct CoordsBody: Codable {
    let body: CoordsData
}

struct CoordsData: Codable {
    let coords: [CoordBody]
    let from: TrackRef
}

struct CoordBody: Codable {
    let coord: CLLocationCoordinate2D
    let boatTime: String
    let boatTimeMillis: UInt64
    let speed: Speed
    let depth: Distance
    let waterTemp: Temperature
}

struct TrackMeta: Codable {
    let trackName: TrackName
    let boatName: BoatName
    let username: Username
}

struct TracksResponse: Codable {
    let tracks: [TrackRef]
}

struct TrackRef: Codable {
    let trackName: TrackName
    let boatName: BoatName
    let username: Username
    
    let startMillis: Double
    let topSpeed: Speed?
    let avgSpeed: Speed?
    let distance: DistanceMillis
    let duration: Duration
    let avgWaterTemp: Temperature?
    let topPoint: CoordBody
    
    var startDate: String { get { return Formats.shared.format(date: start) } }
    var start: Date { return Date(timeIntervalSince1970: startMillis / 1000) }
}

struct TrackStats: Codable {
    let points: Int
    
    static func parse(json: JsObject) throws -> TrackStats {
        return TrackStats(points: try json.readInt("points"))
    }
}

struct AccessToken: Equatable, Hashable, CustomStringConvertible, StringCodable {
    let token: String
    var description: String { return token }
    
    init(_ value: String) {
        self.token = value
    }
    
    static func == (lhs: AccessToken, rhs: AccessToken) -> Bool { return lhs.token == rhs.token }
}

struct BoatName: Equatable, Hashable, CustomStringConvertible, StringCodable {
    let name: String
    var description: String { return name }
    
    init(_ name: String) {
        self.name = name
    }
    
    static func == (lhs: BoatName, rhs: BoatName) -> Bool { return lhs.name == rhs.name }
}

struct TrackName: Equatable, Hashable, CustomStringConvertible, StringCodable {
    let name: String
    var description: String { return name }
    
    init(_ name: String) {
        self.name = name
    }
    
    static func == (lhs: TrackName, rhs: TrackName) -> Bool { return lhs.name == rhs.name }
}

struct Username: Equatable, Hashable, CustomStringConvertible, StringCodable {
    let name: String
    var description: String { return name }
    
    init(_ name: String) {
        self.name = name
    }
    
    static func == (lhs: Username, rhs: Username) -> Bool { return lhs.name == rhs.name }
}

protocol StringCodable: Codable, CustomStringConvertible {
    init(_ value: String)
}

extension StringCodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw.isEmpty {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize value from an empty string"
            )
        }
        self.init(raw)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

protocol NormalIntCodable: Codable {
    init(_ value: Int)
    var value: Int { get }
}

extension NormalIntCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Int.self)
        self.init(raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

protocol IntCodable: Codable {
    init(_ value: UInt64)
    var value: UInt64 { get }
}

extension IntCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(UInt64.self)
        self.init(raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

protocol DoubleCodable: Codable {
    init(_ value: Double)
    var value: Double { get }
}

extension DoubleCodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(Double.self)
        self.init(raw)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct Mmsi: Equatable, Hashable, CustomStringConvertible {
    static let key = "mmsi"
    let mmsi: String
    var description: String { return mmsi }
    
    init(_ mmsi: String) {
        self.mmsi = mmsi
    }
    
    static func == (lhs: Mmsi, rhs: Mmsi) -> Bool { return lhs.mmsi == rhs.mmsi }
    
    static func from(number: UInt64) -> Mmsi { return Mmsi("\(number)") }
}

struct BackendInfo: Codable {
    let name: String
    let version: String
}

struct BoatResponse: Codable {
    let boat: Boat
}

struct Boat: Codable {
    let id: Int
    let name: BoatName
    let token: String
    let addedMillis: UInt64
}

struct UserToken {
    let email: String
    let token: AccessToken
}

struct SimpleMessage: Codable {
    let message: String
}

enum Language: String, Codable {
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

struct UserContainer: Codable {
    let user: UserProfile
}

struct UserProfile: Codable {
    let id: Int
    let username: Username
    let email: String?
    let language: Language
    let boats: [Boat]
    let addedMillis: UInt64
}
