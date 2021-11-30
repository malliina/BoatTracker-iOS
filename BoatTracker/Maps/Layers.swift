//
//  Layers.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 04/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import MapboxMaps

class Layers {
    static let log = LoggerFactory.shared.boat(Layers.self)
    static let boatIcon: String = "boat-resized-opt-30"
    static let stops: [NSNumber: UIColor] = [
        5: UIColor(r: 0, g: 255, b: 150, alpha: 1),
        10: UIColor(r: 50, g: 150, b: 50, alpha: 1),
        15: UIColor(r: 100, g: 255, b: 50, alpha: 1),
        20: UIColor(r: 255, g: 255, b: 0, alpha: 1),
        25: UIColor(r: 255, g: 213, b: 0, alpha: 1),
        28: UIColor(r: 255, g: 191, b: 0, alpha: 1),
        30: UIColor(r: 255, g: 170, b: 0, alpha: 1),
        32: UIColor(r: 255, g: 150, b: 0, alpha: 1),
        33: UIColor(r: 255, g: 140, b: 0, alpha: 1),
        35: UIColor(r: 255, g: 128, b: 0, alpha: 1),
        37: UIColor(r: 255, g: 85, b: 0, alpha: 1),
        38: UIColor(r: 255, g: 42, b: 0, alpha: 1),
        39: UIColor(r: 255, g: 21, b: 0, alpha: 1),
        40: UIColor(r: 255, g: 0, b: 0, alpha: 1),
    ]
    // static let trackColor = NSExpression(format: "mgl_step:from:stops:(\(Speed.key), %@, %@)", UIColor.green, stops)

    static func boatIcon(id: String, source: Source) -> SymbolLayer {
        icon(id: id, iconImageName: boatIcon, source: source)
    }
    
    static func icon(id: String, iconImageName: String, source: Source) -> SymbolLayer {
        var iconLayer = SymbolLayer(id: id)
        // let iconLayer = SymbolLayer(identifier: id, source: source)
        iconLayer.iconImage = .constant(.name(iconImageName))
        // iconLayer.iconScale = NSExpression(forConstantValue: 0.7)
        iconLayer.iconHaloColor = .constant(StyleColor(.white))
        iconLayer.iconRotationAlignment = .constant(.map)
        // iconLayer.source =
        return iconLayer
    }
    
    static func line(id: String, source: Source, color: UIColor = .black, minimumZoomLevel: Double? = nil) -> LineLayer {
        customLine(id: id, source: source, color: StyleColor(color), minimumZoomLevel: minimumZoomLevel)
    }

//    static func trackLine(id: String, source: MGLShapeSource) -> MGLLineStyleLayer {
//        customLine(id: id, source: source, color: trackColor)
//    }

    static func customLine(id: String, source: Source, color: StyleColor, minimumZoomLevel: Double? = nil) -> LineLayer {
        var lineLayer = LineLayer(id: id)
//        let lineLayer = LineLayer(identifier: id, source: source)
        lineLayer.lineJoin = .constant(.round)
        lineLayer.lineCap = .constant(.round)
        //log.info("Installing \(color)")
        lineLayer.lineColor = .constant(color)
        lineLayer.lineWidth = .constant(1)
        if let minimumZoomLevel = minimumZoomLevel {
            lineLayer.minZoom = minimumZoomLevel
        }
        return lineLayer
    }
}

class LayerSource<L: Layer> {
    let source: GeoJSONSource
    let sourceId: String
    var layer: L
    
    init(_ source: GeoJSONSource, layer: L, sourceId: String) {
        self.source = source
        self.sourceId = sourceId
        self.layer = layer
    }
    
    func install(to style: Style, id: String) throws {
        try style.addSource(source, id: id)
    }
}

extension LayerSource where L == LineLayer {
    convenience init(lineId: String, lineColor: UIColor = .black, minimumZoomLevel: Float? = nil) {
        let source = Source(identifier: lineId, shape: nil, options: nil)
        let layer = Layers.line(id: lineId, source: source, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(source, layer: layer)
    }
    
    convenience init(lineId: String, lineColor: NSExpression, minimumZoomLevel: Float? = nil) {
        let source = Source(identifier: lineId, shape: nil, options: nil)
        let layer = Layers.customLine(id: lineId, source: source, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(source, layer: layer)
    }
}

extension LayerSource where L == SymbolLayer {
    convenience init(iconId: String, iconImageName: String) {
        let source = Source(identifier: iconId, shape: nil, options: nil)
        let layer = Layers.icon(id: iconId, iconImageName: iconImageName, source: source)
        self.init(source, layer: layer)
    }
}

extension Style {
    func removeSourceAndLayer(id: String) {
        if let layer = self.layer(withIdentifier: id) {
            self.removeLayer(layer)
        }
        if let source = self.source(withIdentifier: id) {
            self.removeSource(source)
        }
    }
}
