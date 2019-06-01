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
    let marksLayers: Set<String>
    let limitsLayers: Set<String>
    
    init(mapView: MGLMapView, layers: MapboxLayers) {
        self.mapView = mapView
        self.marksLayers = Set(layers.marks)
        self.limitsLayers = Set(layers.limits)
    }
    
    func onTap(point: CGPoint) -> Bool {
        do {
            let marksHandled = try handleMarksTap(point: point)
            if !marksHandled {
                return try handleLimitsTap(point: point)
            }
            return marksHandled
        } catch let err {
            log.error(err.describe)
            return false
        }
    }
    
    private func handleMarksTap(point: CGPoint) throws -> Bool {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: marksLayers).first else { return false }
        do {
            let json = try selected.properties()
            do {
                let mark = try json.validate(MarineSymbol.self)
                let popup = MarkAnnotation(mark: mark, coord: selected.coordinate)
                mapView.selectAnnotation(popup, animated: true)
                return true
            } catch {
                let mark = try json.validate(MinimalMarineSymbol.self)
                let popup = MinimalMarkAnnotation(mark: mark, coord: selected.coordinate)
                mapView.selectAnnotation(popup, animated: true)
                return true
            }
        } catch let err {
            log.info("Failed to parse marine symbol: \(err.describe).")
        }
        return false
    }
    
    private func handleLimitsTap(point: CGPoint) throws -> Bool {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: limitsLayers).first else { return false }
        let limitArea = try selected.properties().validate(RawLimitArea.self).validate()
        let popup = LimitAnnotation(limit: limitArea, coord: mapView.convert(point, toCoordinateFrom: nil))
        mapView.selectAnnotation(popup, animated: true)
        return true
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
