//
//  TapListener.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 06/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import MapboxMaps
import RxSwift
import RxCocoa

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
        let annotation = queryFeatures(at: point).map { features in
            self.handleBoatTap(features) ??
            self.handleAisTap(features) ??
            self.handleMarksTap(features) ??
            self.handleAreaTap(point, features) ??
            self.handleLimitsTap(point, features)
        }
        //mapView.selectAnnotation(annotation, animated: true, completionHandler: nil)
        return true
    }
    
    private func handleMarksTap(_ features: [QueriedFeature]) -> CustomAnnotation? {
        guard let coordinate = markCoordinate(features) else { return nil }
        let full = visibleFeatureProps(features, layers: Array(marksLayers), t: MarineSymbol.self).map { marineSymbol in
            MarkAnnotation(mark: marineSymbol, coord: coordinate)
        }
        let minimal = visibleFeatureProps(features, layers: Array(marksLayers), t: MinimalMarineSymbol.self).map { marineSymbol in
            MinimalMarkAnnotation(mark: marineSymbol, coord: coordinate)
        }
        return full ?? minimal
    }
    
    private func markCoordinate(_ features: [QueriedFeature]) -> CLLocationCoordinate2D? {
        guard let feature = visibleFeature(features, layers: Array(marksLayers))?.feature else { return nil }
        switch feature.geometry {
        case .point(let point): return point.coordinates
        default: return nil
        }
    }
    
    private func handleBoatTap(_ features: [QueriedFeature]) -> BoatAnnotation? {
        visibleFeatureProps(features, layers: Array(boats.layers()), t: BoatPoint.self).map { boatPoint in
            BoatAnnotation(info: boatPoint)
        }
    }
    
    private func handleAisTap(_ features: [QueriedFeature]) -> VesselAnnotation? {
        // Limits feature selection to just the following layer identifiers
        return visibleFeatureProps(features, layers: Array(aisLayers), t: VesselProps.self).flatMap { props in
            ais?.info(props.mmsi).map { vessel in
                VesselAnnotation(vessel: vessel)
            }
        }
    }
    
    private func handleAreaTap(_ point: CGPoint, _ features: [QueriedFeature]) -> FairwayAreaAnnotation? {
        return visibleFeatureProps(features, layers: layers.fairwayAreas, t: FairwayArea.self).map { fairwayAreaProps in
            FairwayAreaAnnotation(
                info: fairwayAreaProps,
                limits: self.limitAreaInfo(features),
                coord: self.mapView.mapboxMap.coordinate(for: point)
            )
        }
    }
    
    private func handleLimitsTap(_ point: CGPoint, _ features: [QueriedFeature]) -> LimitAnnotation? {
        return limitAreaInfo(features).map { area in
            LimitAnnotation(limit: area, coord: self.mapView.mapboxMap.coordinate(for: point))
        }
    }
    
    private func limitAreaInfo(_ features: [QueriedFeature]) -> LimitArea? {
        return visibleFeatureProps(features, layers: Array(limitsLayers), t: RawLimitArea.self).flatMap { raw in
            return try? raw.validate()
        }
    }
    
    func visibleFeatureProps<T: Decodable>(_ features: [QueriedFeature], layers: [String], t: T.Type) -> T? {
        return visibleFeature(features, layers: layers).flatMap { feature in
            return try? Json.shared.parse(t, from: feature.feature.properties ?? [:])
        }
    }
    
    func visibleFeature(_ features: [QueriedFeature], layers: [String]) -> QueriedFeature? {
        features.filter { qf in
            layers.exists { layer in
                qf.sourceLayer == layer
            }
        }.first
    }
    
    func queryFeatures(at: CGPoint) -> Single<[QueriedFeature]> {
        return Observable.create { observer in
            self.mapView.mapboxMap.queryRenderedFeatures(at: at) { result in
                switch result {
                case .success(let features):
                    observer.on(.next(features))
                    observer.on(.completed)
                case .failure(let error):
                    self.log.warn("Failed to query rendered features. \(error)")
                    observer.on(.error(error))
                }
            }
            return Disposables.create()
        }.asSingle()
    }
}
