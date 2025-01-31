import Foundation
import MapboxMaps

class Layers {
  static let log = LoggerFactory.shared.boat(Layers.self)
  static let boatIcon: String = "boat-resized-opt-30"
  static let carIcon: String = "car4"
  static let trophyIcon: String = "trophy-gold-path"
  static let routeStartIcon: String = "flag"
  static let routeEndIcon: String = "flag-checkered"
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

  static func boatIcon(id: String, source: String) -> SymbolLayer {
    icon(id: id, source: source, iconImageName: boatIcon)
  }

  static func icon(
    id: String, source: String, iconImageName: String, iconSize: Double = 0.7
  )
    -> SymbolLayer
  {
    var iconLayer = SymbolLayer(id: id, source: source)
    iconLayer.iconImage = .constant(.name(iconImageName))
    iconLayer.iconSize = .constant(iconSize)
    iconLayer.iconHaloColor = .constant(StyleColor(.white))
    iconLayer.iconRotationAlignment = .constant(.map)
    return iconLayer
  }

  static func line(
    id: String, source: String, color: UIColor = .black,
    minimumZoomLevel: Double? = nil,
    opacity: Double = 1.0, width: Double = 1.0
  )
    -> LineLayer
  {
    customLine(
      id: id, source: source, color: StyleColor(color),
      minimumZoomLevel: minimumZoomLevel,
      opacity: opacity, width: width)
  }

  static func customLine(
    id: String, source: String, color: StyleColor,
    minimumZoomLevel: Double? = nil,
    opacity: Double = 1.0, width: Double = 1.0
  ) -> LineLayer {
    var lineLayer = LineLayer(id: id, source: source)
    lineLayer.lineJoin = .constant(.round)
    lineLayer.lineCap = .constant(.round)
    lineLayer.lineColor = .constant(color)
    lineLayer.lineWidth = .constant(width)
    lineLayer.lineOpacity = .constant(opacity)
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
  var sourceId: String { source.id }

  init(layer: L, source: String) {
    self.source = GeoJSONSource(id: source)
    self.source.data = nil
    self.layer = layer
  }

  func install(to style: MapboxMap, id: String) throws {
    try style.addSource(source)
    try style.addLayer(layer)
    log.info("Added source \(id) and layer to style.")
  }
}

extension LayerSource where L == LineLayer {
  convenience init(
    lineId: String, lineColor: UIColor = .black,
    minimumZoomLevel: Double? = nil,
    opacity: Double = 1.0, width: Double = 1.0
  ) {
    let layer = Layers.line(
      id: lineId, source: lineId, color: lineColor,
      minimumZoomLevel: minimumZoomLevel,
      opacity: opacity, width: width)
    self.init(layer: layer, source: lineId)
  }

  convenience init(
    lineId: String, lineColor: StyleColor, minimumZoomLevel: Double? = nil
  ) {
    let layer = Layers.customLine(
      id: lineId, source: lineId, color: lineColor,
      minimumZoomLevel: minimumZoomLevel)
    self.init(layer: layer, source: lineId)
  }
}

extension LayerSource where L == SymbolLayer {
  convenience init(iconId: String, iconImageName: String, iconSize: Double) {
    let layer = Layers.icon(
      id: iconId, source: iconId, iconImageName: iconImageName,
      iconSize: iconSize)
    self.init(layer: layer, source: iconId)
  }
}

extension MapboxMap {
  func removeSourceAndLayer(id: String) {
    if self.layerExists(withId: id) {
      try? self.removeLayer(withId: id)
    }
    if self.sourceExists(withId: id) {
      try? self.removeSource(withId: id)
    }
  }
}
