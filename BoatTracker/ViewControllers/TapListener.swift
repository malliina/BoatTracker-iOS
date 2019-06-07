//
//  TapListener.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 06/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

class TapListener {
    let log = LoggerFactory.shared.vc(TapListener.self)
    
    let mapView: MGLMapView
    let layers: MapboxLayers
    let marksLayers: Set<String>
    let limitsLayers: Set<String>
    let aisLayers: Set<String>
    let ais: AISRenderer
    let boats: BoatRenderer
    
    init(mapView: MGLMapView, layers: MapboxLayers, ais: AISRenderer, boats: BoatRenderer) {
        self.mapView = mapView
        self.layers = layers
        self.marksLayers = Set(layers.marks)
        self.limitsLayers = Set(layers.limits)
        self.aisLayers = [layers.ais.vessel, layers.ais.trail]
        self.ais = ais
        self.boats = boats
    }
    
    func onTap(point: CGPoint) -> Bool {
        // Preference: boats > ais > marks > fairway info > limits
        // Fairway info includes any limits
        do {
            guard let annotation = try
                (handleBoatTap(point: point)) ??
                (try handleAisTap(point: point)) ??
                (try handleMarksTap(point: point)) ??
                (try handleAreaTap(point: point)) ??
                (try handleLimitsTap(point: point)) else { return false}
            mapView.selectAnnotation(annotation, animated: true)
            return true
        } catch let err {
            log.error(err.describe)
            return false
        }
    }
    
    private func handleMarksTap(point: CGPoint) throws -> MGLAnnotation? {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: marksLayers).first else { return nil }
        do {
            let json = try selected.properties()
            do {
                let mark = try json.validate(MarineSymbol.self)
                return MarkAnnotation(mark: mark, coord: selected.coordinate)
            } catch {
                let mark = try json.validate(MinimalMarineSymbol.self)
                return MinimalMarkAnnotation(mark: mark, coord: selected.coordinate)
            }
        } catch let err {
            log.info("Failed to parse marine symbol: \(err.describe).")
        }
        return nil
    }
    
    private func handleBoatTap(point: CGPoint) -> MGLAnnotation? {
        do {
            if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: boats.layers()).find({ $0 is MGLPointFeature }) {
                let info = try Json.shared.read(BoatPoint.self, dict: selected.attributes)
                return BoatAnnotation(info: info)
            } else {
                return nil
            }
        } catch let err {
            log.error("Unable to handle boat tap. \(err.describe)")
            return nil
        }
    }
    
    private func handleAisTap(point: CGPoint) throws -> MGLAnnotation? {
        // Limits feature selection to just the following layer identifiers
        if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: aisLayers).find({ $0 is MGLPointFeature }),
            let mmsi = selected.attribute(forKey: Mmsi.key) as? String,
            let vessel = ais.info(Mmsi(mmsi)) {
            return VesselAnnotation(vessel: vessel)
        } else {
            return nil
        }
    }
    
    private func handleAreaTap(point: CGPoint) throws -> MGLAnnotation? {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: Set(layers.fairwayAreas)).first else { return nil }
        return FairwayAreaAnnotation(
            info: try selected.properties().validate(FairwayArea.self),
            limits: try limitAreaInfo(point: point),
            coord: mapView.convert(point, toCoordinateFrom: nil))
    }
    
    private func handleLimitsTap(point: CGPoint) throws -> MGLAnnotation? {
        guard let limitArea = try limitAreaInfo(point: point) else { return nil }
        return LimitAnnotation(limit: limitArea, coord: mapView.convert(point, toCoordinateFrom: nil))
    }
    
    private func limitAreaInfo(point: CGPoint) throws -> LimitArea? {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: limitsLayers).first else { return nil }
        return try selected.properties().validate(RawLimitArea.self).validate()
    }
    
    func featureData(point: CGPoint, layers: [String]) throws -> Data? {
        guard let selected = visibleFeature(at: point, layers: marksLayers) else { return nil }
        return try Json.shared.asData(dict: selected.attributes)
    }
    
    func visibleFeature(at: CGPoint, layers: Set<String>) -> MGLFeature? {
        return mapView.visibleFeatures(at: at, styleLayerIdentifiers: layers).first
    }
}

extension MGLFeature {
    func properties() throws -> Data {
        return try Json.shared.asData(dict: self.attributes)
    }
}
