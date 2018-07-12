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

class MapVC: UIViewController, MGLMapViewDelegate, BoatSocketDelegate, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(MapVC.self)
    
    let profileButton = BoatButton.map(icon: #imageLiteral(resourceName: "UserIcon"))
    let followButton = BoatButton.map(icon: #imageLiteral(resourceName: "LocationArrow"))
    
    private var socket: BoatSocket = BoatSocket(token: (try? Keychain.shared.findToken()) ?? nil)
    
    // state of boat trails and icons
    
    var trails: [TrackName: MGLShapeSource] = [:]
    // The history data is in the above trails also but it is difficult to read an MGLShapeSource. This is more suitable for our purposes.
    var history: [TrackName: [CLLocationCoordinate2D]] = [:]
    var icons: [TrackName: MGLSymbolStyleLayer] = [:]
    
    var mapView: MGLMapView?
    var style: MGLStyle?
    
    var mapMode: MapMode = .fit
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket.delegate = self
        
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
        followButton.alpha = mapMode == .follow ? MapButton.deselectedAlpha : MapButton.selectedAlpha
        followButton.addTarget(self, action: #selector(followClicked(_:)), for: .touchUpInside)
        
        // For some reason, I didn't get UISwipeGestureRecognizer to work
        let swipes = UIPanGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        // Prevents this from firing when the user is zooming
        swipes.maximumNumberOfTouches = 1
        swipes.delegate = self
        mapView.addGestureRecognizer(swipes)
    }
    
    @objc func onSwipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            unFollow()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func userClicked(_ sender: UIButton) {
        // WTF?
        if case _?? = try? Keychain.shared.findToken() {
            let dest = ProfileVC()
            dest.delegate = self
            displaySheet(dest: dest)
        } else {
            let dest = AuthVC()
            dest.delegate = self
            displaySheet(dest: dest)
        }
    }
    
    @objc func followClicked(_ sender: UIButton) {
        if mapMode == .stay {
            if let mapView = mapView, let last = history.first?.value.last {
                let current = mapView.camera
                current.centerCoordinate = last
//                mapView.setCenter(last, animated: true)
                mapView.fly(to: current, completionHandler: nil)
            }
            follow()
        } else {
            unFollow()
        }
    }
    
    func follow() {
        mapMode = .follow
        followButton.alpha = MapButton.deselectedAlpha
    }
    
    func unFollow() {
        mapMode = .stay
        followButton.alpha = MapButton.selectedAlpha
    }
    
    func displaySheet(dest: UIViewController) {
        let nav = UINavigationController(rootViewController: dest)
        nav.modalPresentationStyle = .formSheet
        nav.navigationBar.prefersLargeTitles = true
        present(nav, animated: true, completion: nil)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        log.info("didFinishLoading map")
        mapView.bringSubview(toFront: profileButton)
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        log.info("didFinishLoading style")
        self.style = style
        // Add stuff to the map starting here
        socket.open()
    }
    
    func onCoords(event: CoordsData) {
        guard let style = style else { return }
        let track = event.from.trackName
        let coords = event.coords
        log.info("Got \(coords.count) coords")
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
    func initEmptyLayers(track: TrackRef, to style: MGLStyle) -> MGLShapeSource {
        let trailId = trailName(for: track)
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
        let iconId = iconName(for: track)
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
    
    func trailName(for track: TrackRef) -> String {
        return "\(track.boatName)-\(track.trackName)-trail"
    }
    
    func iconName(for track: TrackRef) -> String {
        return "\(track.boatName)-\(track.trackName)-icon"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        log.info("Memory warning.")
    }
}

extension MapVC: TokenDelegate {
    func onToken(token: AccessToken?) {
        socket.delegate = nil
        socket.close()
        socket = BoatSocket(token: token)
        socket.delegate = self
        socket.open()
    }
}
