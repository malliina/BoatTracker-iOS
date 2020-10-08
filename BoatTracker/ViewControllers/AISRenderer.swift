//
//  AISRenderer.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

class AISRenderer {
    let log = LoggerFactory.shared.vc(AISRenderer.self)
    
    private let maxTrailLength = 200
    private let vesselTrails: MGLShapeSource
    private let vesselShape: MGLShapeSource
    private var vesselHistory: [Mmsi: [Vessel]] = [:]
    private var vesselIcons: [Mmsi: MGLSymbolStyleLayer] = [:]
    
    private let mapView: MGLMapView
    private let style: MGLStyle
    private let conf: AisConf
    
    init(mapView: MGLMapView, style: MGLStyle, conf: AisConf) {
        self.mapView = mapView
        self.style = style
        self.conf = conf
        // Icons
        let vessels = LayerSource(iconId: conf.vessel, iconImageName: conf.vesselIcon)
        vessels.layer.iconRotation = NSExpression(forKeyPath: Vessel.headingKey)
        vessels.install(to: style)
        vesselShape = vessels.source
        
        // Trails
        let trails = LayerSource(lineId: conf.trail, lineColor: .darkGray, minimumZoomLevel: 11.0)
        trails.install(to: style)
        vesselTrails = trails.source
    }
    
    func info(_ mmsi: Mmsi) -> Vessel? {
        vesselHistory[mmsi]?.first
    }
    
    func update(vessels: [Vessel]) {
        vessels.forEach { v in
            vesselHistory.updateValue(([v] + (vesselHistory[v.mmsi] ?? [])).take(maxTrailLength), forKey: v.mmsi)
        }
        let updatedVessels: [MGLPointFeature] = vesselHistory.values.compactMap { v in
            guard let latest: Vessel = v.first else { return nil }
            let point = MGLPointFeature()
            point.coordinate = latest.coord
            point.attributes = [
                Mmsi.key: latest.mmsi.mmsi,
                Vessel.nameKey: latest.name,
                Vessel.headingKey: latest.heading ?? latest.cog
            ]
            return point
        }
        vesselShape.shape = MGLShapeCollectionFeature(shapes: updatedVessels)
        let updatedTrails: [MGLPolylineFeature] = vesselHistory.values.compactMap { v in
            let tail = v.dropFirst()
            guard !tail.isEmpty else { return nil }
            return MGLPolylineFeature(coordinates: tail.map { $0.coord }, count: UInt(tail.count))
        }
        vesselTrails.shape = MGLMultiPolylineFeature(polylines: updatedTrails)
        //        log.info("Updated vessel source which now has \(updatedVessels.count) locations.")
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
        vesselTrails.shape = MGLMultiPolylineFeature(polylines: [])
        vesselShape.shape = MGLShapeCollectionFeature(shapes: [])
    }
}
