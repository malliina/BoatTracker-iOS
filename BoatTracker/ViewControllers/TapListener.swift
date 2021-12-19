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
    
    func onTap(point: CGPoint) -> Single<CustomAnnotation?> {
        // Preference: boats > ais > trophy > marks > fairway info > limits
        // Fairway info includes any limits
        return handleBoatTap(point).flatMap { r1 in
            guard r1 == nil else { return Single.just(r1) }
            return self.handleAisTap(point).flatMap { r2 in
                guard r2 == nil else { return Single.just(r2) }
                return self.handleTrophyTap(point).flatMap { tt in
                    guard tt == nil else { return Single.just(tt) }
                    return self.handleMarksTap(point).flatMap { r3 in
                        guard r3 == nil else { return Single.just(r3) }
                        return self.handleAreaTap(point).flatMap { r4 in
                            guard r4 == nil else { return Single.just(r4) }
                            return self.handleLimitsTap(point)
                        }
                    }
                }
                
            }
        }
    }
    
    private func handleMarksTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        return queryFeatures(at: point, layerIds: Array(marksLayers)).map { features in
            guard let coordinate = self.markCoordinate(features.first) else { return nil }
            return features.first.flatMap { feature in
                let props = feature.feature.properties ?? [:]
                let full: MarkAnnotation? = (try? Json.shared.parse(MarineSymbol.self, from: props)).map { symbol in
                    MarkAnnotation(mark: symbol, coord: coordinate)
                }
                let minimal: MinimalMarkAnnotation? = (try? Json.shared.parse(MinimalMarineSymbol.self, from: props)).map { symbol in
                    MinimalMarkAnnotation(mark: symbol, coord: coordinate)
                }
                return full ?? minimal
            }
        }
    }
    
    private func markCoordinate(_ feature: QueriedFeature?) -> CLLocationCoordinate2D? {
        switch feature?.feature.geometry {
        case .point(let point): return point.coordinates
        default: return nil
        }
    }
    
    private func handleBoatTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        queryVisibleFeatureProps(point, layers: Array(boats.layers()), t: BoatPoint.self).map { result in
            result.map { boatPoint in
                BoatAnnotation(info: boatPoint)
            }
        }
    }
    
    private func handleTrophyTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        queryVisibleFeatureProps(point, layers: Array(boats.trophyLayers()), t: TrophyPoint.self).map { result in
            result.map { point in
                TrophyAnnotation(top: point.top)
            }
        }
    }
    
    private func handleAisTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        // Limits feature selection to just the following layer identifiers
        return queryVisibleFeatureProps(point, layers: Array(aisLayers), t: VesselProps.self).map { result in
            guard let props = result, let ais = self.ais else { return nil }
            return ais.info(props.mmsi).map { vessel in
                VesselAnnotation(vessel: vessel)
            }
        }
    }
    
    private func handleAreaTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        return queryVisibleFeatureProps(point, layers: layers.fairwayAreas, t: FairwayArea.self).flatMap { result1 in
            self.queryLimitAreaInfo(point).map { result2 in
                result1.map { area in
                    FairwayAreaAnnotation(info: area, limits: result2, coord: self.mapView.mapboxMap.coordinate(for: point))
                }
            }
            
        }
    }
    
    private func handleLimitsTap(_ point: CGPoint) -> Single<CustomAnnotation?> {
        return queryLimitAreaInfo(point).map { result in
            result.map { area in
                LimitAnnotation(limit: area, coord: self.mapView.mapboxMap.coordinate(for: point))
            }
        }
    }
    
    private func queryLimitAreaInfo(_ point: CGPoint) -> Single<LimitArea?> {
        return queryVisibleFeatureProps(point, layers: Array(limitsLayers), t: RawLimitArea.self).map { raw in
            return try? raw?.validate()
        }
    }
    
    func queryVisibleFeatureProps<T: Decodable>(_ point: CGPoint, layers: [String], t: T.Type) -> Single<T?> {
        return queryFeatures(at: point, layerIds: layers).map { features in
            self.log.info("Found \(features.count) features with layers \(layers.mkString(", ")).")
            return features.first.flatMap { feature in
                let props = feature.feature.properties ?? [:]
                do {
                    return try Json.shared.parse(t, from: props)
                } catch {
                    let str = try! Json.shared.stringify(props)
                    self.log.warn("Failed to parse \(str). \(error)")
                    return nil
                }
            }
        }
    }
    
    func queryFeatures(at: CGPoint, layerIds: [String]) -> Single<[QueriedFeature]> {
        return Observable.create { observer in
            self.mapView.mapboxMap.queryRenderedFeatures(at: at, options: RenderedQueryOptions(layerIds: layerIds, filter: nil)) { result in
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
