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
    let buttonInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    
    private var socket: BoatSocket { Backend.shared.socket }
    private var http: BoatHttpClient { Backend.shared.http }
    
    private var mapView: MGLMapView?
    private var style: MGLStyle?
    
    private var latestToken: UserToken? = nil
    private var isSignedIn: Bool { latestToken != nil }
    
    private var aisRenderer: AISRenderer? = nil
    private var taps: TapListener? = nil
    private var boatRenderer: BoatRenderer? = nil
    private var pathFinder: PathFinder? = nil
    private var settings: UserSettings { UserSettings.shared }
    private var clientConf: ClientConf? { settings.conf }
    
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
        profileButton.contentEdgeInsets = buttonInsets
        profileButton.isHidden = true
        profileButton.addTarget(self, action: #selector(userClicked(_:)), for: .touchUpInside)
        
        mapView.addSubview(followButton)
        followButton.snp.makeConstraints { (make) in
            make.top.equalTo(profileButton.snp.bottom).offset(12)
            make.leadingMargin.equalTo(profileButton.snp.leadingMargin)
            make.height.width.equalTo(buttonSize)
        }
        followButton.contentEdgeInsets = buttonInsets
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
        let boats = BoatRenderer(mapView: mapView, style: style, followButton: followButton)
        self.boatRenderer = boats
        self.pathFinder = PathFinder(mapView: mapView, style: style)
        installTapListener(mapView: mapView)
        // Maybe the conf should be cached in a file?
        let _ = http.conf().subscribe { (event) in
            switch event {
            case .success(let conf): self.initInteractive(mapView: mapView, style: style, layers: conf.layers, boats: boats)
            case .error(let err): self.log.error("Failed to load conf: '\(err.describe)'.")
            }
        }
    }
    
    func initInteractive(mapView: MGLMapView, style: MGLStyle, layers: MapboxLayers, boats: BoatRenderer) {
        if firstInit {
            firstInit = false
            if BoatPrefs.shared.isAisEnabled {
                let ais = AISRenderer(mapView: mapView, style: style, conf: layers.ais)
                self.aisRenderer = ais
            }
            self.taps = TapListener(mapView: mapView, layers: layers, ais: self.aisRenderer, boats: boats)
        }
    }
    
    func initConf() {
        let _ = http.conf().subscribe(onSuccess: { (conf) in
            self.settings.conf = conf
            self.onUiThread {
                self.profileButton.isHidden = false
            }
        }) { (err) in
            self.log.error("Unable to load configuration: '\(err.describe)'.")
        }
    }
    
    func setupUser() {
        if isSignedIn {
            let _ = http.profile().subscribe(onSuccess: { (profile) in
                self.settings.profile = profile
            }) { (err) in
                self.log.error("Unable to load profile: '\(err.describe)'.")
            }
        } else {
            settings.profile = nil
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
            let handledByTaps = taps?.onTap(point: point) ?? false
            if !handledByTaps {
                mapView.deselectAnnotation(mapView.selectedAnnotations.first, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if let annotation = annotation as? TrophyAnnotation, let renderer = boatRenderer {
            return renderer.trophyAnnotationView(annotation: annotation)
        } else if let annotation = annotation as? RouteAnnotation {
            let (id, faIcon) = annotation.isEnd ? ("route-end", "fa-flag-checkered") : ("route-start", "fa-flag")
            return routeAnnotationView(id: id, faIcon: faIcon, of: annotation, mapView: mapView)
        } else {
            // This is for custom annotation views, which we display manually in handleMapTap, I think
            return MGLAnnotationView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }
    
    func routeAnnotationView(id: String, faIcon: String,  of annotation: MGLAnnotation, mapView: MGLMapView) -> MGLAnnotationView {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MGLAnnotationView(annotation: annotation, reuseIdentifier: id)
        if let image = UIImage(icon: faIcon, backgroundColor: .clear, iconColor: UIColor.black, fontSize: 14) {
            let imageView = UIImageView(image: image)
            view.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            view.addSubview(imageView)
        }
        return view
    }
    
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        guard let language = settings.lang else { return nil }
        if let boat = annotation as? BoatAnnotation {
            return TrackedBoatCallout(annotation: boat, lang: language)
        } else if let vessel = annotation as? VesselAnnotation {
            return VesselCallout(annotation: vessel, lang: language)
        } else if let mark = annotation as? MarkAnnotation, let finnishSpecials = settings.languages?.finnish.specialWords {
            return MarkCallout(annotation: mark, lang: language, finnishWords: finnishSpecials)
        } else if let mark = annotation as? MinimalMarkAnnotation, let finnishSpecials = settings.languages?.finnish.specialWords {
            return MinimalMarkCallout(annotation: mark, lang: language, finnishWords: finnishSpecials)
        } else if let limit = annotation as? LimitAnnotation {
            return limit.callout(lang: language)
        } else if let area = annotation as? FairwayAreaAnnotation {
            return area.callout(lang: language)
        } else {
            // Default callout view
            return nil
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        true
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
        true
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
        boatRenderer?.toggleFollow()
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
        pathFinder?.clear()
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
