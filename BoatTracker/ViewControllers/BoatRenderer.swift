import Foundation
import UIKit
import MapboxMaps

class BoatRenderer {
    let log = LoggerFactory.shared.vc(BoatRenderer.self)
    var app: UIApplication { UIApplication.shared }
    // state of boat trails and icons
    private var trails: [TrackName: GeoJSONSource] = [:]
    var isEmpty: Bool { trails.isEmpty }
    // The history data is in the above trails also because it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    private var history: [TrackName: [MeasuredCoord]] = [:]
    private var boatIcons: [TrackName: SymbolLayer] = [:]
    private var trophyIcons: [TrackName: SymbolLayer] = [:]
    var latestTrack: TrackName? = nil
    private var hasBeenFollowing: Bool = false
    
//    private let followButton: UIButton
    private let mapView: MapView
    private let style: Style
    
    var mapMode: MapMode = .fit {
        didSet {
            switch mapMode {
            case .fit:
                app.isIdleTimerDisabled = false
//                followButton.alpha = MapButton.selectedAlpha
            case .follow:
                app.isIdleTimerDisabled = true
//                followButton.alpha = MapButton.deselectedAlpha
            case .stay:
                app.isIdleTimerDisabled = false
//                followButton.alpha = MapButton.selectedAlpha
            }
        }
    }
    
//    init(mapView: MapView, style: Style, followButton: UIButton) {
    init(mapView: MapView, style: Style) {
        self.mapView = mapView
        self.style = style
//        self.followButton = followButton
    }
    
    func layers() -> Set<String> {
        Set(boatIcons.map { (track, layer) -> String in iconName(for: track) })
    }
    
    func trophyLayers() -> Set<String> {
        Set(trophyIcons.map { (track, layer) -> String in trophyName(for: track) })
    }
    
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
        latestTrack = track
        let coords = event.coords
        // Updates boat trail
        let previousTrail = history[track]
        let newTrail = (previousTrail ?? []) + coords
        let isUpdate = previousTrail != nil && !coords.isEmpty
        history.updateValue(newTrail, forKey: track)
        let polyline: FeatureCollection = speedFeatures(coords: newTrail)
        var trail: GeoJSONSource = try trails[track] ?? initEmptyLayers(track: event.from, to: style)
        let coll = GeoJSONSourceData.featureCollection(polyline)
        trail.data = coll
        try style.updateGeoJSONSource(withId: trailName(for: event.from.trackName), geoJSON: .featureCollection(polyline))
        // Updates boat icon position
        guard let lastCoord = coords.last, let iconLayer = boatIcons[track] else { return }
        let dict = try Json.shared.write(from: BoatPoint(from: from, coord: lastCoord))
        let geo = Geometry.point(.init(lastCoord.coord))
        var feature = Feature(geometry: geo)
        feature.properties = dict
        if let iconSourceId = iconLayer.source {
            try style.updateGeoJSONSource(withId: iconSourceId, geoJSON: .feature(feature))
        }
        // Updates boat icon bearing
        let lastTwo = Array(newTrail.suffix(2)).map { $0.coord }
        let bearing = lastTwo.count == 2 ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
        if let bearing = bearing {
            try style.updateLayer(withId: iconLayer.id, type: SymbolLayer.self) { layer in
                layer.iconRotate = .constant(bearing)
            }
        }
        // Updates trophy
        let top = from.topPoint
        guard let trophyLayer = trophyIcons[track] else { return }
        var trophyFeature = Feature(geometry: .point(.init(top.coord)))
        trophyFeature.properties = try Json.shared.write(from: TrophyPoint(top: top))
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
    private func initEmptyLayers(track: TrackRef, to style: Style) throws -> GeoJSONSource {
        let trackName = track.trackName
        let trailId = trailName(for: trackName)
        // Boat trail
        let trailData = LayerSource(lineId: trailId)
        // The line width should gradually increase based on the zoom level
        //        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [18: 3, 9: 10])
        try trailData.install(to: style, id: trailId)
        trails.updateValue(trailData.source, forKey: trackName)
        
        // Boat icon
        let iconId = iconName(for: trackName)
        let iconData = LayerSource(iconId: iconId, iconImageName: Layers.boatIcon, iconSize: 0.7)
        try iconData.install(to: style, id: iconId)
        boatIcons.updateValue(iconData.layer, forKey: trackName)
        
        // Trophy icon
        let trophyId = trophyName(for: trackName)
        let trophyData = LayerSource(iconId: trophyId, iconImageName: Layers.trophyIcon, iconSize: 1.0)
        try trophyData.install(to: style, id: trophyId)
        trophyIcons.updateValue(trophyData.layer, forKey: trackName)
        
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
    
    private func trailName(for track: TrackName) -> String { "\(track)-trail" }
    private func iconName(for track: TrackName) -> String { "\(track)-icon" }
    private func trophyName(for track: TrackName) -> String { "\(track)-trophy" }
    
    func clear() {
        trails.forEach { (track, _) in
            removeTrack(track: track)
        }
        trails = [:]
        history = [:]
        boatIcons = [:]
        trophyIcons = [:]
        latestTrack = nil
    }
    
    private func removeTrack(track: TrackName) {
        style.removeSourceAndLayer(id: trailName(for: track))
        style.removeSourceAndLayer(id: iconName(for: track))
        style.removeSourceAndLayer(id: trophyName(for: track))
    }
}
