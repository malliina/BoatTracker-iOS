//
//  PathFinder.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 16/05/2019.
//  Copyright © 2019 Michael Skogberg. All rights reserved.
//

import Foundation
import Mapbox

class RouteLayers {
    static let empty = RouteLayers(initial: LayerSource(lineId: "route-initial"),
                                   fairways: LayerSource(lineId: "route-fairways"),
                                   tail: LayerSource(lineId: "route-tail"))
    
    let initial: LayerSource<MGLLineStyleLayer>
    let fairways: LayerSource<MGLLineStyleLayer>
    let tail: LayerSource<MGLLineStyleLayer>
    
    init(initial: LayerSource<MGLLineStyleLayer>,fairways: LayerSource<MGLLineStyleLayer>, tail: LayerSource<MGLLineStyleLayer>) {
        self.initial = initial
        self.initial.layer.lineDashPattern = NSExpression(forConstantValue: [2, 4])
        self.fairways = fairways
        self.tail = tail
        self.tail.layer.lineDashPattern = NSExpression(forConstantValue: [2, 4])
    }
    
    func update(initial: [CLLocationCoordinate2D], fairways: [CLLocationCoordinate2D], tail: [CLLocationCoordinate2D]) {
        update(self.initial, initial)
        update(self.fairways, fairways)
        update(self.tail, tail)
    }
    
    func update(_ src: LayerSource<MGLLineStyleLayer>, _ coords: [CLLocationCoordinate2D]) {
        var data = coords
        src.source.shape = MGLPolylineFeature(coordinates: &data, count: UInt(data.count))
    }
    
    func install(to: MGLStyle) {
        initial.install(to: to)
        fairways.install(to: to)
        tail.install(to: to)
    }
}

class PathFinder: NSObject, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(PathFinder.self)
    
    private let mapView: MGLMapView
    private let style: MGLStyle
    
    private let edgePadding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
    
    private var start: RouteAnnotation? = nil
    private var end: RouteAnnotation? = nil
    
    private var current: RouteLayers? = nil
    
    init(mapView: MGLMapView, style: MGLStyle) {
        self.mapView = mapView
        self.style = style
        super.init()
        let longPresses = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:)))
        longPresses.delegate = self
        mapView.addGestureRecognizer(longPresses)
    }
    
    @objc func onLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard let senderView = sender.view else { return }
            let point = sender.location(in: senderView)
            let coord = mapView.convert(point, toCoordinateFrom: nil)
            if let start = start, let end = end {
                mapView.removeAnnotation(start)
                mapView.removeAnnotation(end)
                drawEndpoint(start: end.coordinate)
                drawEndpoint(end: coord)
                shortest(from: end.coordinate, to: coord)
            } else if let start = start {
                drawEndpoint(end: coord)
                shortest(from: start.coordinate, to: coord)
            } else {
                drawEndpoint(start: coord)
            }
        }
    }
    
    func drawEndpoint(start: CLLocationCoordinate2D) {
        let s = RouteAnnotation(at: start, isEnd: false)
        self.start = s
        mapView.addAnnotation(s)
    }
    
    func drawEndpoint(end: CLLocationCoordinate2D) {
        let e = RouteAnnotation(at: end, isEnd: true)
        self.end = e
        mapView.addAnnotation(e)
    }
    
    func shortest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        log.info("Loading shortest route from \(from) to \(to)...")
        let _ = Backend.shared.http.shortestRoute(from: from, to: to).subscribe { (event) in
            switch event {
            case .success(let route):
                self.log.info("Loaded shortest route from \(from) to \(to).")
                self.update(route: route)
            case .failure(let err):
                self.log.error("Failed to load shortest route from \(from) to \(to). \(err.describe)")
            }
        }
    }
    
    func update(route: RouteResult) {
        DispatchQueue.main.async {
            let layers = self.currentLayers()
            let fairwayPath = route.route.links.map { $0.to }
            layers.update(initial: [route.from, fairwayPath.first ?? route.to],
                          fairways: fairwayPath,
                          tail: [fairwayPath.last ?? route.from, route.to])
            let coords = fairwayPath + [ route.from, route.to ]
            let bounds = MGLPolylineFeature(coordinates: coords, count: UInt(coords.count)).overlayBounds
            let camera = self.mapView.cameraThatFitsCoordinateBounds(bounds, edgePadding: self.edgePadding)
            self.mapView.fly(to: camera, completionHandler: nil)
        }
    }

    func currentLayers() -> RouteLayers {
        if let current = current {
            return current
        } else {
            let layers = RouteLayers.empty
            layers.install(to: style)
            current = layers
            return layers
        }
    }
    
    func clear() {
        if let end = end {
            mapView.removeAnnotation(end)
        }
        if let start = start {
            mapView.removeAnnotation(start)
        }
        if let current = current {
            [current.initial, current.fairways, current.tail].forEach { (layerSource) in
                style.removeSourceAndLayer(id: layerSource.layer.identifier)
            }
        }
        start = nil
        end = nil
        current = nil
    }
}
