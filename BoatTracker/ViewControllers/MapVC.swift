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
import RxSwift

struct ActiveMarker {
    let annotation: TrophyAnnotation
    let coord: CoordBody
}

class MapVC: UIViewController, MGLMapViewDelegate, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(MapVC.self)
    
    let profileButton = BoatButton.map(icon: #imageLiteral(resourceName: "SettingsSlider"))
    let followButton = BoatButton.map(icon: #imageLiteral(resourceName: "LocationArrow"))
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    
    private var socket: BoatSocket { return Backend.shared.socket }
    private var http: BoatHttpClient { return Backend.shared.http }
    
    private var mapView: MGLMapView?
    private var style: MGLStyle?
    
    private var latestToken: UserToken? = nil
    private var isSignedIn: Bool { return latestToken != nil }
    
    private var aisRenderer: AISRenderer? = nil
    private var taps: TapListener? = nil
    private var boatRenderer: BoatRenderer? = nil
    private var settings: UserSettings { return UserSettings.shared }
    private var clientConf: ClientConf? { return settings.conf }
    
    private var firstInit: Bool = true
    
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
        followButton.alpha = MapButton.selectedAlpha
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
        initConf()
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.style = style
        self.boatRenderer = BoatRenderer(mapView: mapView, style: style, followButton: followButton)
        installTapListener(mapView: mapView)
        // Maybe the conf should be cached in a file?
        let _ = http.conf().subscribe { (event) in
            switch event {
            case .success(let conf): self.initInteractive(mapView: mapView, style: style, layers: conf.layers)
            case .error(let err): self.log.error("Failed to load conf: '\(err.describe)'.")
            }
        }
    }
    
    func initInteractive(mapView: MGLMapView, style: MGLStyle, layers: MapboxLayers) {
        if firstInit {
            firstInit = false
            self.aisRenderer = AISRenderer(mapView: mapView, style: style, conf: layers.ais)
            self.taps = TapListener(mapView: mapView, marksLayers: layers.marks)
        }
    }
    
    func initConf() {
        let _ = http.conf().subscribe(onSuccess: { (conf) in
            UserSettings.shared.conf = conf
        }) { (err) in
            self.log.error("Unable to load configuration: '\(err.describe)'.")
        }
    }
    
    func setupUser() {
        if isSignedIn {
            let _ = http.profile().subscribe(onSuccess: { (profile) in
                UserSettings.shared.profile = profile
            }) { (err) in
                self.log.error("Unable to load profile: '\(err.describe)'.")
            }
        } else {
            UserSettings.shared.profile = nil
        }
    }
    
    func installTapListener(mapView: MGLMapView) {
        // Tap: See code in https://docs.mapbox.com/ios/maps/examples/runtime-multiple-annotations/
        // Adds a single tap gesture recognizer. This gesture requires the built-in MGLMapView tap gestures (such as those for zoom and annotation selection) to fail.
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
    }
    
    @objc func handleMapTap(sender: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        // https://docs.mapbox.com/ios/maps/examples/runtime-multiple-annotations/
        if sender.state == .ended {
            // Tries matching the exact point first
            guard let senderView = sender.view else { return }
            let point = sender.location(in: senderView)
            let handledByAis = aisRenderer?.onTap(point: point) ?? false
            let handledByTaps = taps?.onTap(point: point) ?? false
            let handled = handledByAis || handledByTaps
            if !handled {
                mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if let annotation = annotation as? TrophyAnnotation, let renderer = boatRenderer {
            return renderer.viewFor(annotation: annotation)
        } else {
            // This is for custom annotation views, which we display manually in handleMapTap, I think
            return MGLAnnotationView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }
    
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        guard let language = settings.lang else { return nil }
        if let vessel = annotation as? VesselAnnotation {
            return VesselCallout(annotation: vessel, lang: language)
        } else if let mark = annotation as? MarkAnnotation, let finnishSpecials = settings.languages?.finnish.specialWords {
            return MarkCallout(annotation: mark, lang: language, finnishWords: finnishSpecials)
        } else if let mark = annotation as? MinimalMarkAnnotation, let finnishSpecials = settings.languages?.finnish.specialWords {
            return MinimalMarkCallout(annotation: mark, lang: language, finnishWords: finnishSpecials)
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
        let isTrophy = annotation as? TrophyAnnotation
        if isTrophy == nil {
            mapView.removeAnnotation(annotation)
        }
    }
    
    @objc func onSwipe(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            boatRenderer?.stay()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func userClicked(_ sender: UIButton) {
        guard let language = settings.lang else {
            log.error("No language info. Cannot open user info.")
            return
        }
        if let user = latestToken {
            let dest = ProfileTableVC(tokenDelegate: self, tracksDelegate: self, current: boatRenderer?.latestTrack, user: user, lang: language)
            navigate(to: dest)
        } else {
            let dest = AuthVC(tokenDelegate: self, welcome: self, lang: language)
            navigate(to: dest)
        }
    }
    
    @objc func followClicked(_ sender: UIButton) {
        boatRenderer?.follow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        log.info("Memory warning.")
    }
    
    /// Called at least once
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
        setupUser()
    }
    
    func change(to track: TrackName) {
        disconnect()
        boatRenderer?.latestTrack = track
        Backend.shared.open(track: track, delegate: self)
    }
    
    func disconnect() {
        socket.delegate = nil
        socket.close()
        removeAllTrails()
        followButton.isHidden = true
    }
    
    func removeAllTrails() {
        boatRenderer?.clear()
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
            self.boatRenderer?.addCoords(event: event)
            let isTrailsEmpty = self.boatRenderer?.isEmpty ?? true
            if !isTrailsEmpty && self.followButton.isHidden {
                self.followButton.isHidden = false
            }
        }
    }
}

extension MapVC: VesselDelegate {
    func on(vessels: [Vessel]) {
        onUiThread {
            self.aisRenderer?.update(vessels: vessels)
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
                if let boatToken = profile.boats.headOption()?.token, let lang = self.settings.lang {
                    self.onUiThread {
                        self.navigate(to: WelcomeSignedIn(boatToken: boatToken, lang: lang.settings))
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
        aisRenderer?.clear()
    }
}
