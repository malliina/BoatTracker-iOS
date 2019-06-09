//
//  BoatRenderer.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 03/02/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import UIKit
import Mapbox

class BoatRenderer {
    let log = LoggerFactory.shared.vc(BoatRenderer.self)
    var app: UIApplication { return UIApplication.shared }
    // state of boat trails and icons
    private var trails: [TrackName: MGLShapeSource] = [:]
    var isEmpty: Bool { return trails.isEmpty }
    // The history data is in the above trails also but it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    private var history: [TrackName: [CLLocationCoordinate2D]] = [:]
    private var boatIcons: [TrackName: MGLSymbolStyleLayer] = [:]
    private var topSpeedMarkers: [TrackName: ActiveMarker] = [:]
    var latestTrack: TrackName? = nil
    private var hasBeenFollowing: Bool = false
    
    private let followButton: UIButton
    private let mapView: MGLMapView
    private let style: MGLStyle
    
    var mapMode: MapMode = .fit {
        didSet {
            switch mapMode {
            case .fit:
                app.isIdleTimerDisabled = false
                followButton.alpha = MapButton.selectedAlpha
            case .follow:
                app.isIdleTimerDisabled = true
                followButton.alpha = MapButton.deselectedAlpha
            case .stay:
                app.isIdleTimerDisabled = false
                followButton.alpha = MapButton.selectedAlpha
            }
        }
    }
    
    init(mapView: MGLMapView, style: MGLStyle, followButton: UIButton) {
        self.mapView = mapView
        self.style = style
        self.followButton = followButton
    }
    
    func layers() -> Set<String> {
        return Set(boatIcons.map { (track, layer) -> String in iconName(for: track) })
    }
    
    func trophyAnnotationView(annotation: TrophyAnnotation) -> MGLAnnotationView {
        let id = "trophy"
        let gold = UIColor(r: 255, g: 215, b: 0, alpha: 1.0)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MGLAnnotationView(annotation: annotation, reuseIdentifier: id)
        if let image = UIImage(icon: "fa-trophy", backgroundColor: .clear, iconColor: gold, fontSize: 14) {
            let imageView = UIImageView(image: image)
            view.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            view.addSubview(imageView)
        }
        return view
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
        let current = mapView.camera
        current.centerCoordinate = last
        mapView.fly(to: current, completionHandler: nil)
    }
    
    func addCoords(event: CoordsData) {
//        log.info("Got coords \(event)")
        let from = event.from
        let track = from.trackName
        latestTrack = track
        let coords = event.coords
        // Updates boat trail
        let newTrail = (history[track] ?? []) + event.coords.map { $0.coord }
        history.updateValue(newTrail, forKey: track)
        var mutableCoords = newTrail
        let polyline = MGLPolylineFeature(coordinates: &mutableCoords, count: UInt(mutableCoords.count))
        let trail = trails[track] ?? initEmptyLayers(track: event.from, to: style)
        trail.shape = polyline
        // Updates boat icon position
        guard let lastCoord = coords.last, let iconLayer = boatIcons[track] else { return }
        do {
            let dict = try Json.shared.write(from: BoatPoint(from: from, coord: lastCoord))
            let point = MGLPointFeature()
            point.coordinate = lastCoord.coord
            point.attributes = dict
            if let iconSourceId = iconLayer.sourceIdentifier,
                let iconSource = style.source(withIdentifier: iconSourceId) as? MGLShapeSource {
                iconSource.shape = point
            }
        } catch let err {
            log.error("Failed to encode JSON. \(err.describe)")
        }
        // Updates boat icon bearing
        let lastTwo = Array(newTrail.suffix(2))
        let bearing = lastTwo.count == 2 ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
        if let bearing = bearing {
            iconLayer.iconRotation = NSExpression(forConstantValue: bearing)
        }
        // Updates trophy
        let top = from.topPoint
        if let old = topSpeedMarkers[from.trackName], old.coord.speed < top.speed {
            let marker = old.annotation
            marker.update(top: top)
            topSpeedMarkers[from.trackName] = ActiveMarker(annotation: marker, coord: top)
        }
        // Updates map position
        switch mapMode {
        case .fit:
            if coords.count > 1 {
                let edgePadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
                let bounds = polyline.overlayBounds
                let destinationCamera = mapView.cameraThatFitsCoordinateBounds(bounds, edgePadding: edgePadding)
                mapView.fly(to: destinationCamera, completionHandler: nil)
                mapMode = .follow
            }
        case .follow:
            guard let lastCoord = coords.last else { return }
            if let bearing = bearing {
                let initialFollowPitch: CGFloat = 60
                let pitch = hasBeenFollowing ? mapView.camera.pitch : initialFollowPitch
                hasBeenFollowing = true
                let camera = MGLMapCamera(lookingAtCenter: lastCoord.coord, altitude: mapView.camera.altitude, pitch: pitch, heading: bearing)
                mapView.fly(to: camera, withDuration: 0.8, completionHandler: nil)
            } else {
                mapView.setCenter(lastCoord.coord, animated: true)
            }
        case .stay:
            ()
        }
    }
    
    // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
    private func initEmptyLayers(track: TrackRef, to style: MGLStyle) -> MGLShapeSource {
        let trailId = trailName(for: track.trackName)
        // Boat trail
        let trailData = LayerSource(lineId: trailId)
        // The line width should gradually increase based on the zoom level
        //        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [18: 3, 9: 10])
        trailData.install(to: style)
        trails.updateValue(trailData.source, forKey: track.trackName)
        
        // Boat icon
        let iconId = iconName(for: track.trackName)
        let iconData = LayerSource(iconId: iconId, iconImageName: Layers.boatIcon)
        iconData.install(to: style)
        boatIcons.updateValue(iconData.layer, forKey: track.trackName)
        
        // Trophy icon
        let top = track.topPoint
        let marker = TrophyAnnotation(top: top)
        topSpeedMarkers[track.trackName] = ActiveMarker(annotation: marker, coord: top)
        mapView.addAnnotation(marker)
        
        return trailData.source
    }
    
    private func trailName(for track: TrackName) -> String {
        return "\(track)-trail"
    }
    
    private func iconName(for track: TrackName) -> String {
        return "\(track)-icon"
    }
    
    func clear() {
        trails.forEach { (track, _) in
            removeTrack(track: track)
        }
        trails = [:]
        history = [:]
        boatIcons = [:]
        topSpeedMarkers = [:]
        latestTrack = nil
    }
    
    private func removeTrack(track: TrackName) {
        style.removeSourceAndLayer(id: trailName(for: track))
        style.removeSourceAndLayer(id: iconName(for: track))
        if let marker = topSpeedMarkers[track]?.annotation {
            mapView.deselectAnnotation(marker, animated: false)
            mapView.removeAnnotation(marker)
        }
    }
}
