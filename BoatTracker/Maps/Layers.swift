//
//  Layers.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 04/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

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
    static let trackColor = NSExpression(format: "mgl_step:from:stops:(\(Speed.key), %@, %@)", UIColor.green, stops)

    static func boatIcon(id: String, source: MGLShapeSource) -> MGLSymbolStyleLayer {
        icon(id: id, iconImageName: boatIcon, source: source)
    }
    
    static func icon(id: String, iconImageName: String, source: MGLShapeSource) -> MGLSymbolStyleLayer {
        let iconLayer = MGLSymbolStyleLayer(identifier: id, source: source)
        iconLayer.iconImageName = NSExpression(forConstantValue: iconImageName)
        iconLayer.iconScale = NSExpression(forConstantValue: 0.7)
        iconLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.white)
        iconLayer.iconRotationAlignment = NSExpression(forConstantValue: "map")
        return iconLayer
    }
    
    static func line(id: String, source: MGLShapeSource, color: UIColor = .black, minimumZoomLevel: Float? = nil) -> MGLLineStyleLayer {
        customLine(id: id, source: source, color: NSExpression(forConstantValue: color), minimumZoomLevel: minimumZoomLevel)
    }

//    static func trackLine(id: String, source: MGLShapeSource) -> MGLLineStyleLayer {
//        customLine(id: id, source: source, color: trackColor)
//    }

    static func customLine(id: String, source: MGLShapeSource, color: NSExpression, minimumZoomLevel: Float? = nil) -> MGLLineStyleLayer {
        let lineLayer = MGLLineStyleLayer(identifier: id, source: source)
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        log.info("Installing \(color)")
        lineLayer.lineColor = color
        lineLayer.lineWidth = NSExpression(forConstantValue: 1)
        if let minimumZoomLevel = minimumZoomLevel {
            lineLayer.minimumZoomLevel = minimumZoomLevel
        }
        return lineLayer
    }
}

class LayerSource<L: MGLStyleLayer> {
    let source: MGLShapeSource
    let layer: L
    
    init(_ source: MGLShapeSource, layer: L) {
        self.source = source
        self.layer = layer
    }
    
    func install(to style: MGLStyle) {
        style.addSource(source)
        style.addLayer(layer)
    }
}

extension LayerSource where L == MGLLineStyleLayer {
    convenience init(lineId: String, lineColor: UIColor = .black, minimumZoomLevel: Float? = nil) {
        let source = MGLShapeSource(identifier: lineId, shape: nil, options: nil)
        let layer = Layers.line(id: lineId, source: source, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(source, layer: layer)
    }
    
    convenience init(lineId: String, lineColor: NSExpression, minimumZoomLevel: Float? = nil) {
        let source = MGLShapeSource(identifier: lineId, shape: nil, options: nil)
        let layer = Layers.customLine(id: lineId, source: source, color: lineColor, minimumZoomLevel: minimumZoomLevel)
        self.init(source, layer: layer)
    }
}

extension LayerSource where L == MGLSymbolStyleLayer {
    convenience init(iconId: String, iconImageName: String) {
        let source = MGLShapeSource(identifier: iconId, shape: nil, options: nil)
        let layer = Layers.icon(id: iconId, iconImageName: iconImageName, source: source)
        self.init(source, layer: layer)
    }
}

extension MGLStyle {
    func removeSourceAndLayer(id: String) {
        if let layer = self.layer(withIdentifier: id) {
            self.removeLayer(layer)
        }
        if let source = self.source(withIdentifier: id) {
            self.removeSource(source)
        }
    }
}
