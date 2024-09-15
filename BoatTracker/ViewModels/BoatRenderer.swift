import Foundation
import MapboxMaps
import SwiftUI
import UIKit

struct TrophyPoint: Codable {
  let from: TrackRef
  var top: CoordBody { from.topPoint }
  var isBoat: Bool { from.sourceType == .boat }
}

struct TrackIds: Hashable {
  let track: TrackName
  let boat: BoatName
  var trail: String { "\(track)-trail" }
  var tappableTrail: String { "\(track)-thick" }
  var icon: String { "\(track)-icon" }
  var trophy: String { "\(track)-trophy" }
  var all: [String] { [trail, tappableTrail, icon, trophy] }
}

class TrackState {
  static let shared = TrackState()
  
  private var history: [TrackName: [CoordBody]] = [:]
  var tracks: [TrackName: [CoordBody]] { history }
  
  func update(track: TrackName, trail: [CoordBody]) {
    history.updateValue(trail, forKey: track)
  }
  
  func clear() {
    history.removeAll()
  }
}

class BoatRenderer {
  let log = LoggerFactory.shared.vc(BoatRenderer.self)
  
  private let mapView: MapView
  private let style: MapboxMap
  private let state = TrackState.shared
  // state of boat trails and icons
  private var trails: [TrackIds: GeoJSONSource] = [:]
  // The history data is in the above trails also because it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
  private var history: [TrackName: [CoordBody]] { state.tracks }
  private var boatIcons: [TrackIds: SymbolLayer] = [:]
  private var trophyIcons: [TrackIds: SymbolLayer] = [:]
  var latestTrack: TrackName? = nil
  private var hasBeenFollowing: Bool = false
  var trailLayerIds: [String] {
    trails.keys.map { ids in
      ids.tappableTrail
    }
  }
  
  @Binding var mapMode: MapMode
  
  @Published private var latestBatch: [CoordBody] = []

  init(mapView: MapView, style: MapboxMap, mapMode: Binding<MapMode>) {
    self.mapView = mapView
    self.style = style
    self._mapMode = mapMode
    Task {
      for await _ in $latestBatch.debounce(for: .seconds(1), scheduler: RunLoop.main).values {
        let edgePadding = UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
        let allCoords = history.values.flatMap { trail in trail.map { point in point.coord } }
        if allCoords.count > 2 {
          log.info("Fitting camera to \(allCoords.count) coords.")
          let camera = await mapView.mapboxMap.camera(
            for: allCoords, padding: edgePadding, bearing: nil, pitch: nil)
          await mapView.camera.fly(to: camera, duration: nil, completion: nil)
        }
      }
    }
  }

  func layers() -> Set<String> {
    Set(boatIcons.map { (track, layer) -> String in track.icon })
  }

  func trophyLayers() -> Set<String> {
    Set(trophyIcons.map { (track, layer) -> String in track.trophy })
  }

  @MainActor
  func toggleFollow() {
    if mapMode == .stay {
      flyToLatest()
      mapMode = .follow
    } else {
      mapMode = .stay
    }
  }

  func stay() {
    mapMode = .stay
  }

  private func flyToLatest() {
    guard let latest = latestCoord() else { return }
    let options = CameraOptions(center: latest.coord)
    mapView.camera?.fly(to: options)
  }
  
  private func latestCoord() -> CoordBody? {
    if let latestTrack = latestTrack, let latest = history[latestTrack]?.last {
      return latest
    } else {
      return history.first?.value.last
    }
  }

  /// Returns true if the input contains a coord less than 10 seconds old, false otherwise
  private func isRecent(coords: [CoordBody]) -> Bool {
    let mostRecentTime = coords.map { body in body.time.millis / 1000 }.max()
    guard let mostRecentTime = mostRecentTime else { return false }
    let ageSeconds = Date.now.timeIntervalSince1970 - Double(mostRecentTime)
    log.debug("Age of \(coords.count) coords is \(ageSeconds) seconds.")
    return ageSeconds < 10
  }
  
  static func adjustedBearing(data: CoordsData) -> CLLocationDirection? {
    let lastTwo = Array(data.coords.suffix(2)).map { $0.coord }
    let bearing = lastTwo.count == 2 ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
    if let bearing = bearing {
      return data.from.sourceType.isBoat ? bearing : (bearing + 90).truncatingRemainder(dividingBy: 360)
    }
    return nil
  }
  
  func addCoords(event: CoordsData) throws {
    let from = event.from
    let track = from.trackName
    let ids = TrackIds(track: track, boat: from.boatName)
    latestTrack = track
    let coords = event.coords
    // Updates boat trail
    let previousTrail = history[track]
    let newTrail = (previousTrail ?? []) + coords
//    let isUpdate = previousTrail != nil && !coords.isEmpty
    state.update(track: track, trail: newTrail)
    let polyline: FeatureCollection = speedFeatures(coords: newTrail, from: from)
    var trail: GeoJSONSource = try trails[ids] ?? initEmptyLayers(track: from, to: style, ids: ids)
    let coll = GeoJSONSourceData.featureCollection(polyline)
    trail.data = coll
    style.updateGeoJSONSource(withId: ids.trail, geoJSON: .featureCollection(polyline))
    style.updateGeoJSONSource(withId: ids.tappableTrail, geoJSON: .featureCollection(polyline))
    // Updates car/boat icon position
    guard let lastCoord = coords.last, let iconLayer = boatIcons[ids] else { return }
    let dict = try Json.shared.write(from: BoatPoint(from: from, coord: lastCoord))
    let geo = Geometry.point(.init(lastCoord.coord))
    var feature = Feature(geometry: geo)
    feature.properties = dict
    if let iconSourceId = iconLayer.source {
      style.updateGeoJSONSource(withId: iconSourceId, geoJSON: .feature(feature))
    }
    let bearing = BoatRenderer.adjustedBearing(data: CoordsData(coords: newTrail, from: from))
    // Updates car/boat icon bearing
    if let bearing = bearing {
      try style.updateLayer(withId: iconLayer.id, type: SymbolLayer.self) { layer in
        layer.iconRotate = .constant(bearing)
      }
    }
    // Updates trophy
    let top = from.topPoint
    guard let trophyLayer = trophyIcons[ids] else { return }
    var trophyFeature = Feature(geometry: .point(.init(top.coord)))
    trophyFeature.properties = try Json.shared.write(
      from: TrophyPoint(from: from))
    if let trophySourceId = trophyLayer.source {
      style.updateGeoJSONSource(withId: trophySourceId, geoJSON: .feature(trophyFeature))
    }
    // Updates map position
    switch mapMode {
    case .fit:
      let shouldFollow = isRecent(coords: coords)
      if shouldFollow && mapMode != .follow {
        log.info("Got realtime update, following...")
        mapMode = .follow
      } else {
        log.info("Not following, mode is fit")
      }
    case .follow:
      guard let lastCoord = coords.last else { return }
      if let bearing = bearing {
        let initialFollowPitch: CGFloat = 60
        let pitch = hasBeenFollowing ? mapView.cameraState.pitch : initialFollowPitch
        hasBeenFollowing = true
        let options = CameraOptions(
          center: lastCoord.coord, padding: .zero, zoom: mapView.cameraState.zoom, bearing: bearing,
          pitch: pitch)
        log.info("Flying with bearing...")
        mapView.camera.fly(to: options, duration: 0.8, completion: nil)
      } else {
        let camera = CameraOptions(center: lastCoord.coord, zoom: mapView.cameraState.zoom)
        log.info("Flying...")
        mapView.camera.fly(to: camera, duration: nil, completion: nil)
      }
    case .stay:
      ()
    }
  }

  // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
  private func initEmptyLayers(track: TrackRef, to style: MapboxMap, ids: TrackIds) throws
    -> GeoJSONSource
  {
    // Removes old trophies and boat icons of the same boat, as we only display one at a time
    let sameBoatIds = trails.keys
      .filter { olds in olds.boat == ids.boat }
    let removableIds =
      sameBoatIds
      .flatMap { ids in [ids.icon, ids.trophy] }
    removeIfExists(ids: removableIds)
    try sameBoatIds.map { ids in ids.trail }.forEach { trailId in
      if style.layerExists(withId: trailId) {
        try style.updateLayer(withId: trailId, type: LineLayer.self) { layer in
          layer.lineOpacity = .constant(0.4)
        }
      }
    }
    // Boat trail
    let trailData = LayerSource(lineId: ids.trail, width: 1.0)
    // The line width should gradually increase based on the zoom level
    //        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [18: 3, 9: 10])
    try trailData.install(to: style, id: ids.trail)
    trails.updateValue(trailData.source, forKey: ids)
    
    // Tappable trail; apparently opacity must be >0 for taps to register; 0.01 is seemingly invisible
    let tappableTrailData = LayerSource(lineId: ids.tappableTrail, opacity: 0.01, width: 10.0)
    try tappableTrailData.install(to: style, id: ids.tappableTrail)
    
    // Boat icon
    let iconId = ids.icon
    let iconData =
      track.sourceType.isBoat
      ? LayerSource(iconId: iconId, iconImageName: Layers.boatIcon, iconSize: 0.7)
      : LayerSource(iconId: iconId, iconImageName: Layers.carIcon, iconSize: 0.5)
    try iconData.install(to: style, id: iconId)
    boatIcons.updateValue(iconData.layer, forKey: ids)

    // Trophy icon
    let trophyData = LayerSource(
      iconId: ids.trophy, iconImageName: Layers.trophyIcon, iconSize: 1.0)
    try trophyData.install(to: style, id: ids.trophy)
    trophyIcons.updateValue(trophyData.layer, forKey: ids)

    return trailData.source
  }

  private func speedFeatures(coords: [CoordBody], from: TrackRef) -> FeatureCollection {
    let features = Array(zip(coords, coords.tail())).map { p1, p2 -> Feature in
      let meta = try? Json.shared.write(from: TrackPoint(from: from, start: p1, end: p2))
      let edge = [p1.coord, p2.coord]
      var feature = Feature(geometry: Geometry.multiPoint(MultiPoint(edge)))
      feature.properties = (meta ?? [:])
      return feature
    }
    return FeatureCollection(features: features)
  }

  func clear() {
    trails.forEach { (ids, _) in
      removeTrack(ids: ids)
    }
    trails = [:]
    state.clear()
    boatIcons = [:]
    trophyIcons = [:]
    latestTrack = nil
  }

  private func removeTrack(ids: TrackIds) {
    removeIfExists(ids: ids.all)
  }

  private func removeIfExists(ids: [String]) {
    ids.forEach { id in
      style.removeSourceAndLayer(id: id)
    }
  }
}
