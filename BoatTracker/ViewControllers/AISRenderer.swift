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
    
    private let headingKey = "heading"
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
        vessels.layer.iconRotation = NSExpression(forKeyPath: Vessel.heading)
        vessels.install(to: style)
        vesselShape = vessels.source
        
        // Trails
        let trails = LayerSource(lineId: conf.trail)
        trails.install(to: style)
        vesselTrails = trails.source
        
        log.info("Initialized vessel source.")
    }
    
    func info(for mmsi: Mmsi) -> Vessel? {
        return vesselHistory[mmsi]?.first
    }
    
    func onTap(point: CGPoint) -> Bool {
        // Limits feature selection to just the following layer identifiers
        let layerIdentifiers: Set = [conf.vessel, conf.trail]
        if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: layerIdentifiers).find({ $0 is MGLPointFeature }),
            let mmsi = selected.attribute(forKey: Mmsi.key) as? String,
            let vessel = vesselHistory[Mmsi(mmsi: mmsi)]?.first {
            let popup = VesselAnnotation(vessel: vessel)
            mapView.selectAnnotation(popup, animated: true)
            return true
        } else {
            return false
        }
    }
    
    func update(vessels: [Vessel]) {
        vessels.forEach { v in
            vesselHistory.updateValue(([v] + (vesselHistory[v.mmsi] ?? [])).take(maxTrailLength), forKey: v.mmsi)
        }
        let updatedVessels: [MGLPointFeature] = vesselHistory.values.compactMap { v in
            guard let latest: Vessel = v.first else { return nil }
            let point = MGLPointFeature()
            point.coordinate = latest.coord
            point.attributes = [Mmsi.key: latest.mmsi.mmsi, Vessel.name: latest.name, Vessel.heading: latest.heading ?? latest.cog]
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
}
