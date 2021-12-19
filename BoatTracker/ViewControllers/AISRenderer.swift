//
//  AISRenderer.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import MapboxMaps

class AISRenderer {
    let log = LoggerFactory.shared.vc(AISRenderer.self)
    
    private let maxTrailLength = 200
    private var vesselTrails: GeoJSONSource
    private var vesselShape: GeoJSONSource
    private var vesselHistory: [Mmsi: [Vessel]] = [:]
    private var vesselIcons: [Mmsi: Layer] = [:]
    
    private let mapView: MapView
    private let style: Style
    private let conf: AisConf
    
    init(mapView: MapView, style: Style, conf: AisConf) throws {
        self.mapView = mapView
        self.style = style
        self.conf = conf
        // Icons
        let vessels = LayerSource(iconId: conf.vessel, iconImageName: conf.vesselIcon, iconSize: 0.7)
        vessels.layer.iconRotate = .expression(Exp(.get) {
            Vessel.headingKey
        })
        try vessels.install(to: style, id: "ais-vessels")
        vesselShape = vessels.source
        
        // Trails
        let trails = LayerSource(lineId: conf.trail, lineColor: .darkGray, minimumZoomLevel: 11.0)
        try trails.install(to: style, id: "ais-trails")
        vesselTrails = trails.source
    }
    
    func info(_ mmsi: Mmsi) -> Vessel? {
        vesselHistory[mmsi]?.first
    }
    
    func update(vessels: [Vessel]) throws {
        vessels.forEach { v in
            vesselHistory.updateValue(([v] + (vesselHistory[v.mmsi] ?? [])).take(maxTrailLength), forKey: v.mmsi)
        }
        let updatedVessels: [Feature] = vesselHistory.values.compactMap { v in
            guard let latest: Vessel = v.first else { return nil }
            let geo = Geometry.point(.init(latest.coord))
            var feature = Feature(geometry: geo)
            do {
                let props = try Json.shared.write(from: VesselMeta(mmsi: latest.mmsi, name: latest.name, heading: latest.heading ?? latest.cog))
                feature.properties = props
                return feature
            } catch {
                log.warn("Failed to write JSON. \(error)")
                return nil
            }
        }
        
        try style.updateGeoJSONSource(withId: "ais-vessels", geoJSON: .featureCollection(FeatureCollection(features: updatedVessels)))
        vesselShape.data = .featureCollection(FeatureCollection(features: updatedVessels))
        let updatedTrails: [Feature] = vesselHistory.values.compactMap { v in
            let tail = v.dropFirst()
            guard !tail.isEmpty else { return nil }
            return Feature(geometry: Geometry.lineString(.init(tail.map { $0.coord })))
        }
        try style.updateGeoJSONSource(withId: "ais-trails", geoJSON: .featureCollection(FeatureCollection(features: updatedTrails)))
        vesselTrails.data = .featureCollection(FeatureCollection(features: updatedTrails))
        log.info("Updated vessel source which now has \(updatedVessels.count) locations.")
    }
    
    /// Clears the map to avoid discontinuities in AIS trails.
    ///
    /// Otherwise the following error occurs:
    ///
    /// 1) The app comes to the foreground, connects, shows AIS trails
    /// 2) The app goes to the background, disconnecting any connections
    /// 3) The app returns to the foreground, reconnects any sockets, then reconnects any trails rendered in step 1)
    ///
    /// In other words, we should always clear trails when the app goes to the background or where there's a socket disconnection
    /// (unless we have persistence, which we don't).
    func clear() {
        log.info("Clearing vessels")
        vesselHistory.removeAll()
        vesselIcons.removeAll()
        vesselTrails.data = .empty
        vesselShape.data = .empty
    }
}
