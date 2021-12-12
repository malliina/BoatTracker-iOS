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

    static func boatIcon(id: String) -> SymbolLayer {
        icon(id: id, iconImageName: boatIcon)
    }
    
    static func icon(id: String, iconImageName: String) -> SymbolLayer {
        var iconLayer = SymbolLayer(id: id)
        iconLayer.iconImage = .constant(.name(iconImageName))
        iconLayer.iconSize = .constant(0.7)
        iconLayer.iconHaloColor = .constant(StyleColor(.white))
        iconLayer.iconRotationAlignment = .constant(.map)
        return iconLayer
    }
    
    static func line(id: String, color: UIColor = .black, minimumZoomLevel: Double? = nil) -> LineLayer {
        customLine(id: id, color: StyleColor(color), minimumZoomLevel: minimumZoomLevel)
    }

    static func customLine(id: String, color: StyleColor, minimumZoomLevel: Double? = nil) -> LineLayer {
        var lineLayer = LineLayer(id: id)
        lineLayer.lineJoin = .constant(.round)
        lineLayer.lineCap = .constant(.round)
        lineLayer.lineColor = .constant(color)
        lineLayer.lineWidth = .constant(1)
        if let minimumZoomLevel = minimumZoomLevel {
            lineLayer.minZoom = minimumZoomLevel
        }
        lineLayer.source = id
        return lineLayer
    }
}

class LayerSource<L: Layer> {
    let log = LoggerFactory.shared.vc(LayerSource.self)
    var source: GeoJSONSource
    var layer: L
    var sourceId: String { layer.id }
    
    init(layer: L) {
        self.source = GeoJSONSource()
        self.source.data = .empty
        self.layer = layer
    }
    
    func install(to style: Style, id: String) throws {
        try style.addSource(source, id: id)
        layer.source = id
        try style.addLayer(layer)
        log.info("Added source \(id) and layer to style.")
    }
}

extension LayerSource where L == LineLayer {
    convenience init(lineId: String, lineColor: UIColor = .black, minimumZoomLevel: Double? = nil) {
        let layer = Layers.line(id: lineId, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(layer: layer)
    }
    
    convenience init(lineId: String, lineColor: StyleColor, minimumZoomLevel: Double? = nil) {
        let layer = Layers.customLine(id: lineId, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(layer: layer)
    }
}

extension LayerSource where L == SymbolLayer {
    convenience init(iconId: String, iconImageName: String) {
        let layer = Layers.icon(id: iconId, iconImageName: iconImageName)
        self.init(layer: layer)
    }
}

extension Style {
    func removeSourceAndLayer(id: String) {
        if let layer = try? self.layer(withId: id) {
            try? self.removeLayer(withId: layer.id)
        }
        if let source = try? self.source(withId: id) {
            try? self.removeSource(withId: id)
        }
    }
}
