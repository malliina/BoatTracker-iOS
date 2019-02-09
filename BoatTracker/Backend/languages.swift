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

struct FairwayLang {
    let fairwayType: String
    let fairwayDepth: String
    let harrowDepth: String
    let minDepth: String
    let maxDepth: String
    let state: String
    
    static func parse(json: JsObject) throws -> FairwayLang {
        return FairwayLang(
            fairwayType: try json.readString("fairwayType"),
            fairwayDepth: try json.readString("fairwayDepth"),
            harrowDepth: try json.readString("harrowDepth"),
            minDepth: try json.readString("minDepth"),
            maxDepth: try json.readString("maxDepth"),
            state: try json.readString("state")
        )
    }
}

struct AisLang {
    let draft: String
    let destination: String
    let shipType: String
    
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

struct MarkLang {
    let markType: String
    let aidType: String
    let navigation: String
    let construction: String, influence: String, location: String, owner: String
    
    static func parse(json: JsObject) throws -> MarkLang {
        return MarkLang(
            markType: try json.readString("markType"),
            aidType: try json.readString("aidType"),
            navigation: try json.readString("navigation"),
            construction: try json.readString("construction"),
            influence: try json.readString("influence"),
            location: try json.readString("location"),
            owner: try json.readString("owner")
        )
    }
}

struct SpecialWords {
    let transportAgency: String
    let defenceForces: String
    let portOfHelsinki: String
    let cityOfHelsinki: String
    let cityOfEspoo: String
    
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
    let name: String
    let qualityClass: String
    let time: String
    let comparisonLevel: String
    let specialWords: SpecialWords
    let fairway: FairwayLang
    let track: TrackLang
    let mark: MarkLang
    let ais: AisLang
    let shipTypes: ShipTypesLang
    
    static func parse(json: JsObject) throws -> Lang {
        return Lang(
            name: try json.readString("name"),
            qualityClass: try json.readString("qualityClass"),
            time: try json.readString("time"),
            comparisonLevel: try json.readString("comparisonLevel"),
            specialWords: try json.readObj("specialWords", parse: SpecialWords.parse),
            fairway: try json.readObj("fairway", parse: FairwayLang.parse),
            track: try json.readObj("track", parse: TrackLang.parse),
            mark: try json.readObj("mark", parse: MarkLang.parse),
            ais: try json.readObj("ais", parse: AisLang.parse),
            shipTypes: try json.readObj("shipTypes", parse: ShipTypesLang.parse)
        )
    }
}

struct Languages {
    let finnish: Lang, swedish: Lang, english: Lang
    
    static func parse(json: JsObject) throws -> Languages {
        return Languages(
            finnish: try json.readObj("finnish", parse: Lang.parse),
            swedish: try json.readObj("swedish", parse: Lang.parse),
            english: try json.readObj("english", parse: Lang.parse)
        )
    }
}

struct ClientConf {
    let languages: Languages
    
    static func parse(json: JsObject) throws -> ClientConf {
        return ClientConf(languages: try json.readObj("languages", parse: Languages.parse))
    }
}
