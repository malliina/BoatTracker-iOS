//
//  TapListener.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 06/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import MapboxMaps

class TapListener {
    let log = LoggerFactory.shared.vc(TapListener.self)
    
    let mapView: MapView
    let layers: MapboxLayers
    let marksLayers: Set<String>
    let limitsLayers: Set<String>
    let aisLayers: Set<String>
    let ais: AISRenderer?
    let boats: BoatRenderer
    
    init(mapView: MapView, layers: MapboxLayers, ais: AISRenderer?, boats: BoatRenderer) {
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
        queryFeatures(at: point) { features in
            <#code#>
        }
        do {
            guard let annotation = try
                (handleBoatTap(point: point)) ??
                (try handleAisTap(point: point)) ??
                (try handleMarksTap(point: point)) ??
                (try handleAreaTap(point: point)) ??
                (try handleLimitsTap(point: point)) else { return false }
            //mapView.selectAnnotation(annotation, animated: true, completionHandler: nil)
            return true
        } catch let err {
            log.error(err.describe)
            return false
        }
    }
    
    private func handleMarksTap(point: CGPoint) throws -> PointAnnotation? {
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
    
    private func handleBoatTap(features: [QueriedFeature]) -> PointAnnotation? {
        do {
            mapView.mapboxMap.queryRenderedFeatures(at: point) { result in
                switch result {
                case .success(let features): features.first?.feature.properties
                case .failure(let error): 41
                }
            }
            if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: boats.layers()).find({ $0 is Feature }) {
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
    
    private func handleAisTap(point: CGPoint) throws -> PointAnnotation? {
        // Limits feature selection to just the following layer identifiers
        if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: aisLayers).find({ $0 is Feature }),
            let mmsi = selected.attribute(forKey: Mmsi.key) as? String,
            let ais = ais,
            let vessel = ais.info(Mmsi(mmsi)) {
            return VesselAnnotation(vessel: vessel)
        } else {
            return nil
        }
    }
    
    private func handleAreaTap(point: CGPoint) throws -> PointAnnotation? {
        visibleFeatureProps(at: point, layers: layers.fairwayAreas, t: FairwayArea.self) { area in
            
        }
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: Set(layers.fairwayAreas)).first else { return nil }
        return FairwayAreaAnnotation(
            info: try selected.properties().validate(FairwayArea.self),
            limits: try limitAreaInfo(point: point),
            coord: mapView.convert(point, toCoordinateFrom: nil)
        )
    }
    
    private func handleLimitsTap(point: CGPoint) throws -> PointAnnotation? {
        guard let limitArea = try limitAreaInfo(point: point) else { return nil }
        return LimitAnnotation(limit: limitArea, coord: mapView.convert(point, toCoordinateFrom: nil))
    }
    
    private func limitAreaInfo(point: CGPoint, onArea: (LimitArea) -> Void) throws {
        visibleFeatureProps(at: point, layers: Array(limitsLayers), t: RawLimitArea.self) { raw in
            guard let area = try? raw.validate() else { return }
            onArea(area)
        }
    }
    
    func visibleFeatureProps<T: Decodable>(at: CGPoint, layers: [String], t: T.Type, onProps: (T) -> Void) {
        visibleFeature(at: at, layers: layers) { feature in
            let parsed = try? Json.shared.parse(t, from: feature.properties ?? [:])
            guard let value = parsed else { return }
            onProps(value)
        }
    }
    
    func visibleFeature(at: CGPoint, layers: [String], onFeature: (Feature) -> Void) {
        mapView.mapboxMap.queryRenderedFeatures(at: at, options: RenderedQueryOptions(layerIds: layers, filter: nil)) { result in
            switch result {
            case .success(let features):
                guard let first = features.first else { return }
                onFeature(first.feature)
            case .failure(let error):
                self.log.warn("Failed to query rendered features. \(error)")
                return
            }
        }
    }
    
    func queryFeatures(at: CGPoint, onFeature: ([QueriedFeature]) -> Void) {
        mapView.mapboxMap.queryRenderedFeatures(at: at) { result in
            switch result {
            case .success(let features):
                onFeature(features)
            case .failure(let error):
                self.log.warn("Failed to query rendered features. \(error)")
                return
            }
        }
    }
}
