//
//  languages.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation

struct SpecialCategory: Codable {
    let fishing, tug, dredger, diveVessel, militaryOps, sailing, pleasureCraft: String
}

struct ShipTypesLang: Codable {
    let special: SpecialCategory
    let wingInGround, highSpeedCraft, pilotVessel, searchAndRescue, searchAndRescueAircraft, portTender, antiPollution, lawEnforce, localVessel, medicalTransport, specialCraft, passenger, cargo, tanker, other, unknown: String
}

struct FairwayStateLang: Codable {
    let confirmed, aihio, mayChange, changeAihio, mayBeRemoved, removed: String
}

struct ZonesLang: Codable {
    let area, fairway, areaAndFairway: String
}

struct FairwayTypesLang: Codable {
    let navigation, anchoring, meetup, harborPool, turn, channel, coastTraffic, core, special, lock, confirmedExtra, helcom, pilot: String
}

struct FairwayLang: Codable {
    let fairwayType, fairwayDepth, harrowDepth, minDepth, maxDepth, state: String
    let states: FairwayStateLang
    let zones: ZonesLang
    let types: FairwayTypesLang
}

struct AisLang: Codable {
    let draft, destination, shipType: String
}

struct TrackLang: Codable {
    let tracks, speed, water, depth, top, duration: String
}

struct MarkTypeLang: Codable {
    let lateral, cardinal, unknown: String
}

struct AidTypeLang: Codable {
    let unknown, lighthouse, sectorLight, leadingMark, directionalLight, minorLight, otherMark, edgeMark, radarTarget, buoy, beacon, signatureLighthouse, cairn: String
}

struct NavMarkLang: Codable {
    let left, right, north, south, west, east, rock, safeWaters, special, notApplicable, unknown: String
}

struct ConstructionLang: Codable {
    let buoyBeacon, iceBuoy, beaconBuoy, superBeacon, exteriorLight, dayBoard, helicopterPlatform, radioMast, waterTower, smokePipe, radarTower, churchTower, superBuoy, edgeCairn, compassCheck, borderMark, borderLineMark, channelEdgeLight, tower: String
}

struct MarkLang: Codable {
    let markType, aidType, navigation, construction, influence, location, owner: String
    let types: MarkTypeLang
    let navTypes: NavMarkLang
    let structures: ConstructionLang
    let aidTypes: AidTypeLang
}

struct SpecialWords: Codable {
    let transportAgency, defenceForces, portOfHelsinki, cityOfHelsinki, cityOfEspoo: String
}

struct SettingsLang: Codable {
    let welcome, welcomeText, laterText, notifications, notificationsText, howItWorks, signIn, signInText, boat, token, tokenText, tokenTextLong, rename, renameBoat, newName, cancel, back: String
}

struct Lang: Codable {
    let language: Language
    let name, qualityClass, time, comparisonLevel: String
    let specialWords: SpecialWords
    let fairway: FairwayLang
    let track: TrackLang
    let mark: MarkLang
    let ais: AisLang
    let shipTypes: ShipTypesLang
    let attributions: AttributionInfo
}

struct Languages: Codable {
    let finnish, swedish, english: Lang
}

struct AisConf: Codable {
    let vessel, trail, vesselIcon: String
    
    static func parse(json: JsObject) throws -> AisConf {
        return AisConf(
            vessel: try json.readString("vessel"),
            trail: try json.readString("trail"),
            vesselIcon: try json.readString("vesselIcon")
        )
    }
}

struct MapboxLayers: Codable {
    let marks: [String]
    let ais: AisConf
}

struct ClientConf: Codable {
    let languages: Languages
    let layers: MapboxLayers
}
