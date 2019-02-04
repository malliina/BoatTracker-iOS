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
    static let boatIcon: String = "boat-resized-opt-30"
    static func boatIcon(id: String, source: MGLShapeSource) -> MGLSymbolStyleLayer {
        return icon(id: id, iconImageName: "boat-resized-opt-30", source: source)
    }
    
    static func icon(id: String, iconImageName: String, source: MGLShapeSource) -> MGLSymbolStyleLayer {
        let iconLayer = MGLSymbolStyleLayer(identifier: id, source: source)
        iconLayer.iconImageName = NSExpression(forConstantValue: iconImageName)
        iconLayer.iconScale = NSExpression(forConstantValue: 0.7)
        iconLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.white)
        iconLayer.iconRotationAlignment = NSExpression(forConstantValue: "map")
        return iconLayer
    }
    
    static func line(id: String, source: MGLShapeSource) -> MGLLineStyleLayer {
        let lineLayer = MGLLineStyleLayer(identifier: id, source: source)
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.black)
        lineLayer.lineWidth = NSExpression(forConstantValue: 1)
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
    convenience init(lineId: String) {
        let source = MGLShapeSource(identifier: lineId, shape: nil, options: nil)
        let layer = Layers.line(id: lineId, source: source)
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
