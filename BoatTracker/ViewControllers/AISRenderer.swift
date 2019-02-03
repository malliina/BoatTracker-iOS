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
    
    private let aisVesselLayer = "ais-vessels"
    private let aisTrailLayer = "ais-vessels-trails"
    
    private let headingKey = "heading"
    private let maxTrailLength = 200
    private var vesselTrails: MGLShapeSource? = nil
    private var vesselShape: MGLShapeSource? = nil
    private var vesselHistory: [Mmsi: [Vessel]] = [:]
    private var vesselIcons: [Mmsi: MGLSymbolStyleLayer] = [:]
    
    private let mapView: MGLMapView
    private let style: MGLStyle
    
    init(mapView: MGLMapView, style: MGLStyle) {
        self.mapView = mapView
        self.style = style
    }
    
    func info(for mmsi: Mmsi) -> Vessel? {
        return vesselHistory[mmsi]?.first
    }
    
    func onTap(point: CGPoint) -> Bool {
        // Limits feature selection to just the following layer identifiers
        let layerIdentifiers: Set = [aisVesselLayer, aisTrailLayer]
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
        if vesselShape == nil {
            initLayers()
        }
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
        vesselShape?.shape = MGLShapeCollectionFeature(shapes: updatedVessels)
        let updatedTrails: [MGLPolylineFeature] = vesselHistory.values.compactMap { v in
            let tail = v.dropFirst()
            guard !tail.isEmpty else { return nil }
            return MGLPolylineFeature(coordinates: tail.map { $0.coord }, count: UInt(tail.count))
        }
        vesselTrails?.shape = MGLMultiPolylineFeature(polylines: updatedTrails)
        //        log.info("Updated vessel source which now has \(updatedVessels.count) locations.")
    }
    
    private func initLayers() {
        // Icons
        let vesselIconSource = MGLShapeSource(identifier: aisVesselLayer, shape: nil, options: nil)
        let vesselIconLayer = MGLSymbolStyleLayer(identifier: aisVesselLayer, source: vesselIconSource)
        vesselIconLayer.iconImageName = NSExpression(forConstantValue: "boat-resized-opt-30")
        vesselIconLayer.iconScale = NSExpression(forConstantValue: 0.7)
        vesselIconLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.white)
        vesselIconLayer.iconRotation = NSExpression(forKeyPath: Vessel.heading)
        style.addSource(vesselIconSource)
        style.addLayer(vesselIconLayer)
        vesselShape = vesselIconSource
        
        // Trails
        let vesselTrailsSource = MGLShapeSource(identifier: aisTrailLayer, shape: nil, options: nil)
        let vesselTrailLayer = MGLLineStyleLayer(identifier: aisTrailLayer, source: vesselTrailsSource)
        vesselTrailLayer.lineJoin = NSExpression(forConstantValue: "round")
        vesselTrailLayer.lineCap = NSExpression(forConstantValue: "round")
        vesselTrailLayer.lineColor = NSExpression(forConstantValue: UIColor.black)
        vesselTrailLayer.lineWidth = NSExpression(forConstantValue: 1)
        style.addSource(vesselTrailsSource)
        style.addLayer(vesselTrailLayer)
        vesselTrails = vesselTrailsSource
        
        log.info("Initialized vessel source.")
    }
}
