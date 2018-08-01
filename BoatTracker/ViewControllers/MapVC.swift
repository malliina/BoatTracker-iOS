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

class MapVC: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(MapVC.self)
    
    let profileButton = BoatButton.map(icon: #imageLiteral(resourceName: "UserIcon"))
    let followButton = BoatButton.map(icon: #imageLiteral(resourceName: "LocationArrow"))
    
    private var socket: BoatSocket { return Backend.shared.socket }
    
    // state of boat trails and icons
    var trails: [TrackName: MGLShapeSource] = [:]
    // The history data is in the above trails also but it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    var history: [TrackName: [CLLocationCoordinate2D]] = [:]
    var icons: [TrackName: MGLSymbolStyleLayer] = [:]
    
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
    
    var latestToken: AccessToken? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "mapbox://styles/malliina/cjgny1fjc008p2so90sbz8nbv")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        self.mapView = mapView
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9), zoomLevel: 10, animated: false)
        view.addSubview(mapView)
        
        mapView.delegate = self
        
        let buttonSize = 40
        mapView.addSubview(profileButton)
        profileButton.snp.makeConstraints { (make) in
            make.topMargin.leadingMargin.equalToSuperview().offset(12)
            make.height.width.equalTo(buttonSize)
        }
        profileButton.addTarget(self, action: #selector(userClicked(_:)), for: .touchUpInside)
        
        mapView.addSubview(followButton)
        followButton.snp.makeConstraints { (make) in
            make.top.equalTo(profileButton.snp.bottom).offset(12)
            make.leadingMargin.equalTo(profileButton.snp.leadingMargin)
            make.height.width.equalTo(buttonSize)
        }
        followButton.isHidden = true
        followButton.alpha = mapMode == .follow ? MapButton.deselectedAlpha : MapButton.selectedAlpha
        followButton.addTarget(self, action: #selector(followClicked(_:)), for: .touchUpInside)
        
        // For some reason, I didn't get UISwipeGestureRecognizer to work
        let swipes = UIPanGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        // Prevents this from firing when the user is zooming
        swipes.maximumNumberOfTouches = 1
        swipes.delegate = self
        mapView.addGestureRecognizer(swipes)
        
        MapEvents.shared.delegate = self
        
        GoogleAuth.shared.delegate = self
        GoogleAuth.shared.signInSilently()
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
        if latestToken != nil {
            let dest = ProfileVC(tracksDelegate: self)
            dest.delegate = self
            navigate(to: dest)
        } else {
            let dest = AuthVC()
            dest.delegate = self
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
        let track = event.from.trackName
        let coords = event.coords
//        log.info("Got \(coords.count) coords")
        // updates boat trail
        let newTrail = (history[track] ?? []) + event.coords.map { $0.coord }
        history.updateValue(newTrail, forKey: track)
        var mutableCoords = newTrail
        let polyline = MGLPolylineFeature(coordinates: &mutableCoords, count: UInt(mutableCoords.count))
        let trail = trails[track] ?? initEmptyLayers(track: event.from, to: style)
        trail.shape = polyline
        // updates boat icon position
        guard let lastCoord = coords.last?.coord, let iconLayer = icons[track] else { return }
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
    
    // https://www.mapbox.com/ios-sdk/examples/runtime-animate-line/
    func initEmptyLayers(track: TrackMeta, to style: MGLStyle) -> MGLShapeSource {
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
        icons.updateValue(iconLayer, forKey: track.trackName)
        style.addLayer(iconLayer)
        
        return trackSource
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
    
    func reload(token: AccessToken?) {
        latestToken = token
        socket.delegate = nil
        socket.close()
        onUiThread {
            self.removeAllTrails()
            self.followButton.isHidden = true
        }
        Backend.shared.updateToken(new: token)
        socket.delegate = self
        socket.open()
    }
    
    func change(to track: TrackName) {
        disconnect()
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
        icons = [:]
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

extension MapVC: TokenDelegate {
    func onToken(token: AccessToken?) {
        reload(token: token)
    }
}

extension MapVC: MapDelegate {
    func close() {
        disconnect()
    }
}
