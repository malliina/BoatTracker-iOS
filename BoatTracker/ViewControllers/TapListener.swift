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
    
    let marksLayers: Set = [
        "marks-turvavesi",
        "marks-kummeli",
        "marks-sektoriloisto",
        "marks-speed-limit",
        "marks-merimajakka",
        "marks-tunnusmajakka",
        "marks-no-waves",
        "marks-linjamerkki",
        "marks-tutka",
        "lateral-green",
        "lateral-red",
        "cardinal-west",
        "cardinal-south",
        "cardinal-east",
        "cardinal-north"
    ]
    
    let mapView: MGLMapView
    
    init(mapView: MGLMapView) {
        self.mapView = mapView
    }
    
    func onTap(point: CGPoint) -> Bool {
        guard let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: marksLayers).first else { return false }
        do {
            let mark = try MarineSymbol.parse(json: JsObject(dict: selected.attributes.mapValues { $0 as AnyObject }))
//            log.info("Tapped \((mark.nameFi ?? mark.nameSe) ?? "unknown")")
            let popup = MarkAnnotation(mark: mark, coord: selected.coordinate)
            mapView.selectAnnotation(popup, animated: true)
            return true
        } catch let err {
            log.info("Failed to parse marine symbol: \(err.describe).")
        }
        return false
    }
}
