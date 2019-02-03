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
    let log = LoggerFactory.shared.vc(AISRenderer.self)
    
    // state of boat trails and icons
    private var trails: [TrackName: MGLShapeSource] = [:]
    var isEmpty: Bool { return trails.isEmpty }
    // The history data is in the above trails also but it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    private var history: [TrackName: [CLLocationCoordinate2D]] = [:]
    private var boatIcons: [TrackName: MGLSymbolStyleLayer] = [:]
    private var topSpeedMarkers: [TrackName: ActiveMarker] = [:]
    var latestTrack: TrackName? = nil
    
    private let followButton: UIButton
    private let mapView: MGLMapView
    private let style: MGLStyle
    
    var mapMode: MapMode = .fit {
        didSet {
            switch mapMode {
            case .fit:
                followButton.alpha = MapButton.selectedAlpha
            case .follow:
                followButton.alpha = MapButton.deselectedAlpha
            case .stay:
                followButton.alpha = MapButton.selectedAlpha
            }
        }
    }
    
    init(mapView: MGLMapView, style: MGLStyle, followButton: UIButton) {
        self.mapView = mapView
        self.style = style
        self.followButton = followButton
    }
    
    func viewFor(annotation: TrophyAnnotation) -> MGLAnnotationView {
        let id = "trophy"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MGLAnnotationView(annotation: annotation, reuseIdentifier: id)
        if let image = UIImage(icon: "fa-trophy", backgroundColor: .clear, iconColor: UIColor(r: 255, g: 215, b: 0, alpha: 1.0), fontSize: 14) {
            let imageView = UIImageView(image: image)
            view.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            view.addSubview(imageView)
        }
        return view
    }
    
    func follow() {
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
        let from = event.from
        let track = from.trackName
        latestTrack = track
        let coords = event.coords
        // updates boat trail
        let newTrail = (history[track] ?? []) + event.coords.map { $0.coord }
        history.updateValue(newTrail, forKey: track)
        var mutableCoords = newTrail
        let polyline = MGLPolylineFeature(coordinates: &mutableCoords, count: UInt(mutableCoords.count))
        let trail = trails[track] ?? initEmptyLayers(track: event.from, to: style)
        trail.shape = polyline
        // updates boat icon position
        guard let lastCoord = coords.last?.coord, let iconLayer = boatIcons[track] else { return }
        let point = MGLPointFeature()
        point.coordinate = lastCoord
        if let iconSourceId = iconLayer.sourceIdentifier,
            let iconSource = style.source(withIdentifier: iconSourceId) as? MGLShapeSource {
            iconSource.shape = point
        }
        // Updates boat icon bearing
        let lastTwo = Array(newTrail.suffix(2))
        if lastTwo.count == 2 {
            let bearing = Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1])
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
                let destinationCamera = mapView.cameraThatFitsCoordinateBounds(polyline.overlayBounds, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
                mapView.fly(to: destinationCamera, completionHandler: nil)
                mapMode = .follow
            }
        case .follow:
            guard let lastCoord = coords.last else { return }
            mapView.setCenter(lastCoord.coord, animated: true)
        case .stay:
            ()
        }
    }
    
    // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
    private func initEmptyLayers(track: TrackRef, to style: MGLStyle) -> MGLShapeSource {
        let trailId = trailName(for: track.trackName)
        let trackSource = MGLShapeSource(identifier: trailId, shape: nil, options: nil)
        style.addSource(trackSource)
        trails.updateValue(trackSource, forKey: track.trackName)
        
        // Boat trail
        let layer = MGLLineStyleLayer(identifier: trailId, source: trackSource)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineColor = NSExpression(forConstantValue: UIColor.black)
        
        // The line width should gradually increase based on the zoom level.
        //        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [18: 3, 9: 10])
        layer.lineWidth = NSExpression(forConstantValue: 1)
        style.addLayer(layer)
        
        // Boat icon
        let iconId = iconName(for: track.trackName)
        let iconSource = MGLShapeSource(identifier: iconId, shape: nil, options: nil)
        style.addSource(iconSource)
        let iconLayer = MGLSymbolStyleLayer(identifier: iconId, source: iconSource)
        iconLayer.iconImageName = NSExpression(forConstantValue: "boat-resized-opt-30")
        iconLayer.iconScale = NSExpression(forConstantValue: 0.7)
        iconLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.white)
        boatIcons.updateValue(iconLayer, forKey: track.trackName)
        style.addLayer(iconLayer)
        
        // Trophy icon
        let top = track.topPoint
        let marker = TrophyAnnotation(top: top)
        topSpeedMarkers[track.trackName] = ActiveMarker(annotation: marker, coord: top)
        mapView.addAnnotation(marker)
        
        return trackSource
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
        mapMode = .fit
    }
    
    private func removeTrack(track: TrackName) {
        let tName = trailName(for: track)
        let iName = iconName(for: track)
        if let trail = style.layer(withIdentifier: tName) {
            style.removeLayer(trail)
        }
        if let trailSource = style.source(withIdentifier: tName) {
            style.removeSource(trailSource)
        }
        if let icon = style.layer(withIdentifier: iName) {
            style.removeLayer(icon)
        }
        if let iconSource = style.source(withIdentifier: iName) {
            style.removeSource(iconSource)
        }
        if let marker = topSpeedMarkers[track]?.annotation {
            mapView.deselectAnnotation(marker, animated: false)
            mapView.removeAnnotation(marker)
        }
    }
}
