//
//  ViewController.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import UIKit
import SnapKit
import Mapbox
import GoogleSignIn

struct ActiveMarker {
    let annotation: MGLPointAnnotation
    let coord: CoordBody
}

class MapVC: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(MapVC.self)
    
    let profileButton = BoatButton.map(icon: #imageLiteral(resourceName: "SettingsSlider"))
    let followButton = BoatButton.map(icon: #imageLiteral(resourceName: "LocationArrow"))
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    
    private var socket: BoatSocket { return Backend.shared.socket }
    
    // state of boat trails and icons
    var trails: [TrackName: MGLShapeSource] = [:]
    // The history data is in the above trails also but it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    var history: [TrackName: [CLLocationCoordinate2D]] = [:]
    var boatIcons: [TrackName: MGLSymbolStyleLayer] = [:]
    var topSpeedMarkers: [TrackName: ActiveMarker] = [:]
    
    var mapView: MGLMapView?
    var style: MGLStyle?
    
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
    
    var latestToken: UserToken? = nil
    var latestTrack: TrackName? = nil
    
    // AIS-related variables. TODO Move to its own module.
    let aisVesselLayer = "ais-vessels"
    let aisTrailLayer = "ais-vessels-trails"
    let headingKey = "heading"
    let maxTrailLength = 200
    var vesselTrails: MGLShapeSource? = nil
    var vesselShape: MGLShapeSource? = nil
    var vesselHistory: [Mmsi: [Vessel]] = [:]
    var vesselIcons: [Mmsi: MGLSymbolStyleLayer] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "mapbox://styles/malliina/cjgny1fjc008p2so90sbz8nbv")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        self.mapView = mapView
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(defaultCenter, zoomLevel: 10, animated: false)
        view.addSubview(mapView)
        
        mapView.delegate = self
        
        let buttonSize = 40
        mapView.addSubview(profileButton)
        profileButton.snp.makeConstraints { (make) in
            make.topMargin.leadingMargin.equalToSuperview().offset(12)
            make.height.width.equalTo(buttonSize)
        }
        profileButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        profileButton.addTarget(self, action: #selector(userClicked(_:)), for: .touchUpInside)
        
        mapView.addSubview(followButton)
        followButton.snp.makeConstraints { (make) in
            make.top.equalTo(profileButton.snp.bottom).offset(12)
            make.leadingMargin.equalTo(profileButton.snp.leadingMargin)
            make.height.width.equalTo(buttonSize)
        }
        followButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        followButton.isHidden = true
        followButton.alpha = mapMode == .follow ? MapButton.deselectedAlpha : MapButton.selectedAlpha
        followButton.addTarget(self, action: #selector(followClicked(_:)), for: .touchUpInside)
        
        // For some reason, I didn't get UISwipeGestureRecognizer to work
        let swipes = UIPanGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        // Prevents this from firing when the user is zooming
        swipes.maximumNumberOfTouches = 1
        swipes.delegate = self
        mapView.addGestureRecognizer(swipes)
        // Tap: See code in https://docs.mapbox.com/ios/maps/examples/runtime-multiple-annotations/
        // Adds a single tap gesture recognizer. This gesture requires the built-in MGLMapView tap gestures (such as those for zoom and annotation selection) to fail.
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        MapEvents.shared.delegate = self
        
        GoogleAuth.shared.delegate = self
        GoogleAuth.shared.signInSilently()
    }
    
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        // https://docs.mapbox.com/ios/maps/examples/runtime-multiple-annotations/
        if sender.state == .ended {
            // Limit feature selection to just the following layer identifiers.
            let layerIdentifiers: Set = [aisVesselLayer, aisTrailLayer]
            
            // Try matching the exact point first.
            guard let senderView = sender.view else { return }
            let point = sender.location(in: senderView)
            if let selected = mapView.visibleFeatures(at: point, styleLayerIdentifiers: layerIdentifiers).find({ $0 is MGLPointFeature }),
                let mmsi = selected.attribute(forKey: Mmsi.key) as? String,
                let vessel = vesselHistory[Mmsi(mmsi: mmsi)]?.first {
                    let popup = VesselAnnotation(vessel: vessel)
                    mapView.selectAnnotation(popup, animated: true)
            } else {
                mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        let id = "trophy"
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) {
            return view
        } else {
            if let annotation = annotation as? MGLPointAnnotation {
                let view = MGLAnnotationView(annotation: annotation, reuseIdentifier: id)
                if let image = UIImage(icon: "fa-trophy", backgroundColor: .clear, iconColor: UIColor(r: 255, g: 215, b: 0, alpha: 1.0), fontSize: 14) {
                    let imageView = UIImageView(image: image)
                    view.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                    view.addSubview(imageView)
                }
                return view
            } else {
                return MGLAnnotationView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        if let vessel = annotation as? VesselAnnotation {
            return VesselCallout(annotation: vessel)
        } else {
            // Default callout view
            return nil
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        mapView.deselectAnnotation(annotation, animated: true)
    }
    
    func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
        let isTrophy = annotation as? MGLPointAnnotation
        if isTrophy == nil {
            mapView.removeAnnotation(annotation)
        }
    }
    
    @objc func onSwipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            mapMode = .stay
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func userClicked(_ sender: UIButton) {
        if let user = latestToken {
            let dest = ProfileTableVC(tokenDelegate: self, tracksDelegate: self, current: latestTrack, user: user)
            navigate(to: dest)
        } else {
            let dest = AuthVC(tokenDelegate: self, welcome: self)
            navigate(to: dest)
        }
    }
    
    @objc func followClicked(_ sender: UIButton) {
        if mapMode == .stay {
            if let mapView = mapView, let last = history.first?.value.last {
                let current = mapView.camera
                current.centerCoordinate = last
                mapView.fly(to: current, completionHandler: nil)
            }
            mapMode = .follow
        } else {
            mapMode = .stay
        }
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.style = style
        // Add stuff to the map starting here
    }
    
    private func addCoords(event: CoordsData) {
        guard let style = style else { return }
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
        // updates boat icon bearing
        let lastTwo = Array(newTrail.suffix(2))
        if lastTwo.count == 2 {
            let bearing = Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1])
            iconLayer.iconRotation = NSExpression(forConstantValue: bearing)
        }
        if !trails.isEmpty && followButton.isHidden {
            followButton.isHidden = false
        }
        // updates trophy
        let top = from.topPoint
        if let old = topSpeedMarkers[from.trackName], old.coord.speed < top.speed {
            let marker = old.annotation
            fill(trophy: marker, top: top)
            topSpeedMarkers[from.trackName] = ActiveMarker(annotation: marker, coord: top)
        }
        // updates map position
        guard let mapView = mapView else { return }
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
    
    func info(for mmsi: Mmsi) -> Vessel? {
        return vesselHistory[mmsi]?.first
    }
    
    private func update(vessels: [Vessel]) {
        if vesselShape == nil {
            // Icons
            let vesselIconSource = MGLShapeSource(identifier: aisVesselLayer, shape: nil, options: nil)
            let vesselIconLayer = MGLSymbolStyleLayer(identifier: aisVesselLayer, source: vesselIconSource)
            vesselIconLayer.iconImageName = NSExpression(forConstantValue: "boat-resized-opt-30")
            vesselIconLayer.iconScale = NSExpression(forConstantValue: 0.7)
            vesselIconLayer.iconHaloColor = NSExpression(forConstantValue: UIColor.white)
            vesselIconLayer.iconRotation = NSExpression(forKeyPath: Vessel.heading)
            style?.addSource(vesselIconSource)
            style?.addLayer(vesselIconLayer)
            vesselShape = vesselIconSource
            
            // Trails
            let vesselTrailsSource = MGLShapeSource(identifier: aisTrailLayer, shape: nil, options: nil)
            let vesselTrailLayer = MGLLineStyleLayer(identifier: aisTrailLayer, source: vesselTrailsSource)
            vesselTrailLayer.lineJoin = NSExpression(forConstantValue: "round")
            vesselTrailLayer.lineCap = NSExpression(forConstantValue: "round")
            vesselTrailLayer.lineColor = NSExpression(forConstantValue: UIColor.black)
            vesselTrailLayer.lineWidth = NSExpression(forConstantValue: 1)
            style?.addSource(vesselTrailsSource)
            style?.addLayer(vesselTrailLayer)
            vesselTrails = vesselTrailsSource
            
            log.info("Initialized vessel source.")
        }
        vessels.forEach { v in
            vesselHistory.updateValue(([v] + (vesselHistory[v.mmsi] ?? [])).take(maxTrailLength), forKey: v.mmsi)
        }
        let updatedVessels: [MGLPointFeature] = vesselHistory.values.compactMap { v in
            guard let latest: Vessel = v.first else { return nil }
            let point = MGLPointFeature()
            point.coordinate = latest.coord
            point.attributes = [Mmsi.key: latest.mmsi.mmsi, Vessel.name: latest.name, Vessel.heading: latest.heading ?? latest.cog]
            return point
        }
        vesselShape?.shape = MGLShapeCollectionFeature(shapes: updatedVessels)
        let updatedTrails: [MGLPolylineFeature] = vesselHistory.values.compactMap { v in
            let tail = v.dropFirst()
            guard !tail.isEmpty else { return nil }
            return MGLPolylineFeature(coordinates: tail.map { $0.coord }, count: UInt(tail.count))
        }
        vesselTrails?.shape = MGLMultiPolylineFeature(polylines: updatedTrails)
//        log.info("Updated vessel source which now has \(updatedVessels.count) locations.")
    }
    
    // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
    func initEmptyLayers(track: TrackRef, to style: MGLStyle) -> MGLShapeSource {
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
        let marker = MGLPointAnnotation()
        fill(trophy: marker, top: top)
        topSpeedMarkers[track.trackName] = ActiveMarker(annotation: marker, coord: top)
        mapView?.addAnnotation(marker)
        
        return trackSource
    }
    
    func fill(trophy: MGLPointAnnotation, top: CoordBody) {
        trophy.title = top.speed.description
        trophy.subtitle = top.boatTime
        trophy.coordinate = top.coord
    }
    
    func trailName(for track: TrackName) -> String {
        return "\(track)-trail"
    }
    
    func iconName(for track: TrackName) -> String {
        return "\(track)-icon"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        log.info("Memory warning.")
    }
    
    func reload(token: UserToken?) {
        latestToken = token
        socket.delegate = nil
        socket.close()
        onUiThread {
            self.removeAllTrails()
            self.followButton.isHidden = true
        }
        Backend.shared.updateToken(new: token)
        socket.delegate = self
        socket.vesselDelegate = self
        socket.open()
    }
    
    func change(to track: TrackName) {
        disconnect()
        latestTrack = track
        Backend.shared.open(track: track, delegate: self)
    }
    
    func disconnect() {
        socket.delegate = nil
        socket.close()
        removeAllTrails()
        followButton.isHidden = true
    }
    
    func removeAllTrails() {
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
    
    func removeTrack(track: TrackName) {
        guard let style = style else { return }
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
            mapView?.deselectAnnotation(marker, animated: false)
            mapView?.removeAnnotation(marker)
        }
    }
}

extension MapVC: TracksDelegate {
    func onTrack(_ track: TrackName) {
        change(to: track)
    }
}

extension MapVC: BoatSocketDelegate {
    func onCoords(event: CoordsData) {
        onUiThread {
            self.addCoords(event: event)
        }
    }
}

extension MapVC: VesselDelegate {
    func on(vessels: [Vessel]) {
        onUiThread {
            self.update(vessels: vessels)
        }
    }
}

extension MapVC: TokenDelegate {
    func onToken(token: UserToken?) {
        reload(token: token)
    }
}

extension MapVC: WelcomeDelegate {
    func showWelcome(token: UserToken?) {
        BoatPrefs.shared.isWelcomeRead = true
        let _ = Backend.shared.http.profile().subscribe { (event) in
            switch event {
            case .success(let profile):
                if let boatToken = profile.boats.headOption()?.token {
                    self.onUiThread {
                        self.navigate(to: WelcomeSignedIn(boatToken: boatToken))
                    }
                } else {
                    self.log.warn("Signed in but user has no boats.")
                }
            case .error(let err):
                self.log.error(err.describe)
            }
        }
    }
}

extension MapVC: MapDelegate {
    func close() {
        disconnect()
    }
}
