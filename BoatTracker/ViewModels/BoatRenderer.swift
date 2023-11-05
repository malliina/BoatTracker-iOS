import Foundation
import UIKit
import MapboxMaps
import SwiftUI

struct TrophyPoint: Codable {
    let top: CoordBody
    let sourceType: SourceType
    var isBoat: Bool { sourceType == .boat }
}

struct TrackIds: Hashable {
    let track: TrackName
    let boat: BoatName
    var trail: String { "\(track)-trail" }
    var icon: String { "\(track)-icon" }
    var trophy: String { "\(track)-trophy" }
    var all: [String] { [ trail, icon, trophy ] }
}

class BoatRenderer {
    let log = LoggerFactory.shared.vc(BoatRenderer.self)
    // state of boat trails and icons
    private var trails: [TrackIds: GeoJSONSource] = [:]
    var isEmpty: Bool { trails.isEmpty }
    // The history data is in the above trails also because it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    private var history: [TrackName: [MeasuredCoord]] = [:]
    private var boatIcons: [TrackIds: SymbolLayer] = [:]
    private var trophyIcons: [TrackIds: SymbolLayer] = [:]
    var latestTrack: TrackName? = nil
    private var hasBeenFollowing: Bool = false
    
    private let mapView: MapView
    private let style: Style
    
    @Binding var mapMode: MapMode
    
    init(mapView: MapView, style: Style, mapMode: Binding<MapMode>) {
        self.mapView = mapView
        self.style = style
        self._mapMode = mapMode
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
        guard let last = history.first?.value.last else { return }
        let options = CameraOptions(center: last.coord)
        mapView.camera?.fly(to: options)
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
        let isUpdate = previousTrail != nil && !coords.isEmpty
        history.updateValue(newTrail, forKey: track)
        let polyline: FeatureCollection = speedFeatures(coords: newTrail)
        var trail: GeoJSONSource = try trails[ids] ?? initEmptyLayers(track: from, to: style, ids: ids)
        let coll = GeoJSONSourceData.featureCollection(polyline)
        trail.data = coll
        try style.updateGeoJSONSource(withId: ids.trail, geoJSON: .featureCollection(polyline))
        // Updates car/boat icon position
        guard let lastCoord = coords.last, let iconLayer = boatIcons[ids] else { return }
        let dict = try Json.shared.write(from: BoatPoint(from: from, coord: lastCoord))
        let geo = Geometry.point(.init(lastCoord.coord))
        var feature = Feature(geometry: geo)
        feature.properties = dict
        if let iconSourceId = iconLayer.source {
            try style.updateGeoJSONSource(withId: iconSourceId, geoJSON: .feature(feature))
        }
        // Updates car/boat icon bearing
        let lastTwo = Array(newTrail.suffix(2)).map { $0.coord }
        let bearing = lastTwo.count == 2 ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
        if let bearing = bearing {
            let adjustedBearing = from.sourceType.isBoat ? bearing : (bearing + 90).truncatingRemainder(dividingBy: 360)
            try style.updateLayer(withId: iconLayer.id, type: SymbolLayer.self) { layer in
                layer.iconRotate = .constant(adjustedBearing)
            }
        }
        // Updates trophy
        let top = from.topPoint
        guard let trophyLayer = trophyIcons[ids] else { return }
        var trophyFeature = Feature(geometry: .point(.init(top.coord)))
        trophyFeature.properties = try Json.shared.write(from: TrophyPoint(top: top, sourceType: from.sourceType))
        if let trophySourceId = trophyLayer.source {
            try style.updateGeoJSONSource(withId: trophySourceId, geoJSON: .feature(trophyFeature))
        }
        // Updates map position
        switch mapMode {
        case .fit:
            if coords.count > 1 {
                let edgePadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
                let allCoords = newTrail.map { $0.coord }
                let camera = mapView.mapboxMap.camera(for: allCoords, padding: edgePadding, bearing: nil, pitch: nil)
                mapView.camera.fly(to: camera, duration: nil, completion: nil)
                if isUpdate {
                    mapMode = .follow
                }
            }
        case .follow:
            guard let lastCoord = coords.last else { return }
            if let bearing = bearing {
                let initialFollowPitch: CGFloat = 60
                let pitch = hasBeenFollowing ? mapView.cameraState.pitch : initialFollowPitch
                hasBeenFollowing = true
                let camera = CameraOptions(center: lastCoord.coord, padding: .zero, zoom: mapView.cameraState.zoom, bearing: bearing, pitch: pitch)
                mapView.camera.fly(to: camera, duration: 0.8, completion: nil)
            } else {
                let camera = CameraOptions(center: lastCoord.coord, zoom: mapView.cameraState.zoom)
                mapView.camera.fly(to: camera, duration: nil, completion: nil)
            }
        case .stay:
            ()
        }
    }
    
    // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
    private func initEmptyLayers(track: TrackRef, to style: Style, ids: TrackIds) throws -> GeoJSONSource {
        // Removes old trophies and boat icons of the same boat, as we only display one at a time
        let sameBoatIds = trails.keys
            .filter { olds in olds.boat == ids.boat }
        let removableIds = sameBoatIds
            .flatMap { ids in [ ids.icon, ids.trophy ] }
        removeIfExists(ids: removableIds)
        try sameBoatIds.map { ids in ids.trail }.forEach { trailId in
            if style.layerExists(withId: trailId) {
                try style.updateLayer(withId: trailId, type: LineLayer.self) { layer in
                    layer.lineOpacity = .constant(0.4)
                }
            }
        }
        // Boat trail
        let trailData = LayerSource(lineId: ids.trail)
        // The line width should gradually increase based on the zoom level
        //        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [18: 3, 9: 10])
        try trailData.install(to: style, id: ids.trail)
        trails.updateValue(trailData.source, forKey: ids)
        
        // Boat icon
        let iconId = ids.icon
        let iconData = track.sourceType.isBoat ?
            LayerSource(iconId: iconId, iconImageName: Layers.boatIcon, iconSize: 0.7) :
            LayerSource(iconId: iconId, iconImageName: Layers.carIcon, iconSize: 0.5)
        try iconData.install(to: style, id: iconId)
        boatIcons.updateValue(iconData.layer, forKey: ids)
        
        // Trophy icon
        let trophyData = LayerSource(iconId: ids.trophy, iconImageName: Layers.trophyIcon, iconSize: 1.0)
        try trophyData.install(to: style, id: ids.trophy)
        trophyIcons.updateValue(trophyData.layer, forKey: ids)
        
        return trailData.source
    }
    
    private func speedFeatures(coords: [MeasuredCoord]) -> FeatureCollection {
        let features = Array(zip(coords, coords.tail())).map { p1, p2 -> Feature in
            let avgSpeed = [p1.speed.knots, p2.speed.knots].reduce(0, +) / 2.0
            let meta = try? Json.shared.write(from: TrackPoint(speed: avgSpeed.knots))
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
        history = [:]
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
