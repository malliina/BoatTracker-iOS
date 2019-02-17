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
    
    init(mapView: MGLMapView, marksLayers: [String]) {
        self.mapView = mapView
        self.marksLayers = Set(marksLayers)
    }
    
    func onTap(point: CGPoint) -> Bool {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: marksLayers).first else { return false }
        do {
            let json = try JSONSerialization.data(withJSONObject: selected.attributes, options: .prettyPrinted)
//            log.info(String(data: json, encoding: .utf8) ?? "No JSON string")
            let decoder = JSONDecoder()
            do {
                let mark = try decoder.decode(MarineSymbol.self, from: json)
                let popup = MarkAnnotation(mark: mark, coord: selected.coordinate)
                mapView.selectAnnotation(popup, animated: true)
                return true
            } catch {
                let mark = try decoder.decode(MinimalMarineSymbol.self, from: json)
                let popup = MinimalMarkAnnotation(mark: mark, coord: selected.coordinate)
                mapView.selectAnnotation(popup, animated: true)
                return true
            }
        } catch let err {
            log.info("Failed to parse marine symbol: \(err.describe).")
        }
        return false
    }
}
