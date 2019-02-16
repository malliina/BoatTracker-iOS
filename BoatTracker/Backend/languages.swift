//
//  languages.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 09/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation

struct SpecialCategory {
    let fishing: String
    let tug: String
    let dredger: String
    let diveVessel: String
    let militaryOps: String
    let sailing: String
    let pleasureCraft: String
    
    static func parse(json: JsObject) throws -> SpecialCategory {
        return SpecialCategory(
            fishing: try json.readString("fishing"),
            tug: try json.readString("tug"),
            dredger: try json.readString("dredger"),
            diveVessel: try json.readString("diveVessel"),
            militaryOps: try json.readString("militaryOps"),
            sailing: try json.readString("sailing"),
            pleasureCraft: try json.readString("pleasureCraft")
        )
    }
}

struct ShipTypesLang {
    let wingInGround: String
    let special: SpecialCategory
    let highSpeedCraft: String
    let pilotVessel: String
    let searchAndRescue: String
    let searchAndRescueAircraft: String
    let portTender: String
    let antiPollution: String
    let lawEnforce: String
    let localVessel: String
    let medicalTransport: String
    let specialCraft: String
    let passenger: String
    let cargo: String
    let tanker: String
    let other: String
    let unknown: String
    
    static func parse(json: JsObject) throws -> ShipTypesLang {
        return ShipTypesLang(
            wingInGround: try json.readString("wingInGround"),
            special: try json.readObj("special", parse: SpecialCategory.parse),
            highSpeedCraft: try json.readString("highSpeedCraft"),
            pilotVessel: try json.readString("pilotVessel"),
            searchAndRescue: try json.readString("searchAndRescue"),
            searchAndRescueAircraft: try json.readString("searchAndRescueAircraft"),
            portTender: try json.readString("portTender"),
            antiPollution: try json.readString("antiPollution"),
            lawEnforce: try json.readString("lawEnforce"),
            localVessel: try json.readString("localVessel"),
            medicalTransport: try json.readString("medicalTransport"),
            specialCraft: try json.readString("specialCraft"),
            passenger: try json.readString("passenger"),
            cargo: try json.readString("cargo"),
            tanker: try json.readString("tanker"),
            other: try json.readString("other"),
            unknown: try json.readString("unknown")
        )
    }
}

struct FairwayStateLang {
    let confirmed, aihio, mayChange, changeAihio, mayBeRemoved, removed: String
    
    static func parse(json: JsObject) throws -> FairwayStateLang {
        return FairwayStateLang(
            confirmed: try json.readString("confirmed"),
            aihio: try json.readString("aihio"),
            mayChange: try json.readString("mayChange"),
            changeAihio: try json.readString("changeAihio"),
            mayBeRemoved: try json.readString("mayBeRemoved"),
            removed: try json.readString("removed")
        )
    }
}

struct ZonesLang {
    let area, fairway, areaAndFairway: String
    
    static func parse(json: JsObject) throws -> ZonesLang {
        return ZonesLang(
            area: try json.readString("area"),
            fairway: try json.readString("fairway"),
            areaAndFairway: try json.readString("areaAndFairway")
        )
    }
}

struct FairwayTypesLang {
    let navigation, anchoring, meetup, harborPool, turn, channel, coastTraffic, core, special, lock, confirmedExtra, helcom, pilot: String
    
    static func parse(json: JsObject) throws -> FairwayTypesLang {
        return FairwayTypesLang(
            navigation: try json.readString("navigation"),
            anchoring: try json.readString("anchoring"),
            meetup: try json.readString("meetup"),
            harborPool: try json.readString("harborPool"),
            turn: try json.readString("turn"),
            channel: try json.readString("channel"),
            coastTraffic: try json.readString("coastTraffic"),
            core: try json.readString("core"),
            special: try json.readString("special"),
            lock: try json.readString("lock"),
            confirmedExtra: try json.readString("confirmedExtra"),
            helcom: try json.readString("helcom"),
            pilot: try json.readString("pilot")
        )
    }
}

struct FairwayLang {
    let fairwayType, fairwayDepth, harrowDepth, minDepth, maxDepth, state: String
    let states: FairwayStateLang
    let zones: ZonesLang
    let types: FairwayTypesLang
    
    static func parse(json: JsObject) throws -> FairwayLang {
        return FairwayLang(
            fairwayType: try json.readString("fairwayType"),
            fairwayDepth: try json.readString("fairwayDepth"),
            harrowDepth: try json.readString("harrowDepth"),
            minDepth: try json.readString("minDepth"),
            maxDepth: try json.readString("maxDepth"),
            state: try json.readString("state"),
            states: try json.readObj("states", parse: FairwayStateLang.parse),
            zones: try json.readObj("zones", parse: ZonesLang.parse),
            types: try json.readObj("types", parse: FairwayTypesLang.parse)
        )
    }
}

struct AisLang {
    let draft, destination, shipType: String
    
    static func parse(json: JsObject) throws -> AisLang {
        return AisLang(
            draft: try json.readString("draft"),
            destination: try json.readString("destination"),
            shipType: try json.readString("shipType")
        )
    }
}

struct TrackLang {
    let tracks: String
    let speed: String
    let water: String
    let depth: String
    let top: String
    let duration: String
    
    static func parse(json: JsObject) throws -> TrackLang {
        return TrackLang(
            tracks: try json.readString("tracks"),
            speed: try json.readString("speed"),
            water: try json.readString("water"),
            depth: try json.readString("depth"),
            top: try json.readString("top"),
            duration: try json.readString("duration")
        )
    }
}

struct MarkTypeLang {
    let lateral, cardinal, unknown: String
    
    static func parse(json: JsObject) throws -> MarkTypeLang {
        return MarkTypeLang(
            lateral: try json.readString("lateral"),
            cardinal: try json.readString("cardinal"),
            unknown: try json.readString("unknown")
        )
    }
}

struct AidTypeLang {
    let unknown, lighthouse, sectorLight, leadingMark, directionalLight, minorLight, otherMark, edgeMark, radarTarget, buoy, beacon, signatureLighthouse, cairn: String
    
    static func parse(json: JsObject) throws -> AidTypeLang {
        return AidTypeLang(
            unknown: try json.readString("unknown"),
            lighthouse: try json.readString("lighthouse"),
            sectorLight: try json.readString("sectorLight"),
            leadingMark: try json.readString("leadingMark"),
            directionalLight: try json.readString("directionalLight"),
            minorLight: try json.readString("minorLight"),
            otherMark: try json.readString("otherMark"),
            edgeMark: try json.readString("edgeMark"),
            radarTarget: try json.readString("radarTarget"),
            buoy: try json.readString("buoy"),
            beacon: try json.readString("beacon"),
            signatureLighthouse: try json.readString("signatureLighthouse"),
            cairn: try json.readString("cairn")
        )
    }
}

struct NavMarkLang {
    let left, right, north, south, west, east, rock, safeWaters, special, notApplicable, unknown: String
    
    static func parse(json: JsObject) throws -> NavMarkLang {
        return NavMarkLang(
            left: try json.readString("left"),
            right: try json.readString("right"),
            north: try json.readString("north"),
            south: try json.readString("south"),
            west: try json.readString("west"),
            east: try json.readString("east"),
            rock: try json.readString("rock"),
            safeWaters: try json.readString("safeWaters"),
            special: try json.readString("special"),
            notApplicable: try json.readString("notApplicable"),
            unknown: try json.readString("unknown")
        )
    }
}

struct ConstructionLang {
    let buoyBeacon, iceBuoy, beaconBuoy, superBeacon, exteriorLight, dayBoard, helicopterPlatform, radioMast, waterTower, smokePipe, radarTower, churchTower, superBuoy, edgeCairn, compassCheck, borderMark, borderLineMark, channelEdgeLight, tower: String
    
    static func parse(json: JsObject) throws -> ConstructionLang {
        return ConstructionLang(
            buoyBeacon: try json.readString("buoyBeacon"),
            iceBuoy: try json.readString("iceBuoy"),
            beaconBuoy: try json.readString("beaconBuoy"),
            superBeacon: try json.readString("superBeacon"),
            exteriorLight: try json.readString("exteriorLight"),
            dayBoard: try json.readString("dayBoard"),
            helicopterPlatform: try json.readString("helicopterPlatform"),
            radioMast: try json.readString("radioMast"),
            waterTower: try json.readString("waterTower"),
            smokePipe: try json.readString("smokePipe"),
            radarTower: try json.readString("radarTower"),
            churchTower: try json.readString("churchTower"),
            superBuoy: try json.readString("superBuoy"),
            edgeCairn: try json.readString("edgeCairn"),
            compassCheck: try json.readString("compassCheck"),
            borderMark: try json.readString("borderMark"),
            borderLineMark: try json.readString("borderLineMark"),
            channelEdgeLight: try json.readString("channelEdgeLight"),
            tower: try json.readString("tower")
        )
    }
}

struct MarkLang {
    let markType, aidType, navigation, construction, influence, location, owner: String
    let types: MarkTypeLang
    let navTypes: NavMarkLang
    let structures: ConstructionLang
    let aidTypes: AidTypeLang
    
    static func parse(json: JsObject) throws -> MarkLang {
        return MarkLang(
            markType: try json.readString("markType"),
            aidType: try json.readString("aidType"),
            navigation: try json.readString("navigation"),
            construction: try json.readString("construction"),
            influence: try json.readString("influence"),
            location: try json.readString("location"),
            owner: try json.readString("owner"),
            types: try json.readObj("types", parse: MarkTypeLang.parse),
            navTypes: try json.readObj("navTypes", parse: NavMarkLang.parse),
            structures: try json.readObj("structures", parse: ConstructionLang.parse),
            aidTypes: try json.readObj("aidTypes", parse: AidTypeLang.parse)
        )
    }
}

struct SpecialWords {
    let transportAgency, defenceForces, portOfHelsinki, cityOfHelsinki, cityOfEspoo: String
    
    static func parse(json: JsObject) throws -> SpecialWords {
        return SpecialWords(
            transportAgency: try json.readString("transportAgency"),
            defenceForces: try json.readString("defenceForces"),
            portOfHelsinki: try json.readString("portOfHelsinki"),
            cityOfHelsinki: try json.readString("cityOfHelsinki"),
            cityOfEspoo: try json.readString("cityOfEspoo")
        )
    }
}

struct Lang {
    let language: Language
    let name, qualityClass, time, comparisonLevel: String
    let specialWords: SpecialWords
    let fairway: FairwayLang
    let track: TrackLang
    let mark: MarkLang
    let ais: AisLang
    let shipTypes: ShipTypesLang
    let attributions: AttributionInfo
    
    static func parse(json: JsObject) throws -> Lang {
        return Lang(
            language: Language.parse(s: try json.readString("language")),
            name: try json.readString("name"),
            qualityClass: try json.readString("qualityClass"),
            time: try json.readString("time"),
            comparisonLevel: try json.readString("comparisonLevel"),
            specialWords: try json.readObj("specialWords", parse: SpecialWords.parse),
            fairway: try json.readObj("fairway", parse: FairwayLang.parse),
            track: try json.readObj("track", parse: TrackLang.parse),
            mark: try json.readObj("mark", parse: MarkLang.parse),
            ais: try json.readObj("ais", parse: AisLang.parse),
            shipTypes: try json.readObj("shipTypes", parse: ShipTypesLang.parse),
            attributions: try json.readObj("attributions", parse: AttributionInfo.parse)
        )
    }
}

struct Languages {
    let finnish, swedish, english: Lang
    
    static func parse(json: JsObject) throws -> Languages {
        return Languages(
            finnish: try json.readObj("finnish", parse: Lang.parse),
            swedish: try json.readObj("swedish", parse: Lang.parse),
            english: try json.readObj("english", parse: Lang.parse)
        )
    }
}

struct AisConf {
    let vessel, trail, vesselIcon: String
    
    static func parse(json: JsObject) throws -> AisConf {
        return AisConf(
            vessel: try json.readString("vessel"),
            trail: try json.readString("trail"),
            vesselIcon: try json.readString("vesselIcon")
        )
    }
}

struct MapboxLayers {
    let marks: [String]
    let ais: AisConf
    
    static func parse(json: JsObject) throws -> MapboxLayers {
        return MapboxLayers(
            marks: try json.readStringArray("marks"),
            ais: try json.readObj("ais", parse: AisConf.parse)
        )
    }
}

struct ClientConf {
    let languages: Languages
    let layers: MapboxLayers
    
    static func parse(json: JsObject) throws -> ClientConf {
        return ClientConf(
            languages: try json.readObj("languages", parse: Languages.parse),
            layers: try json.readObj("layers", parse: MapboxLayers.parse)
        )
    }
}
