import Foundation
import MapboxMaps

class RouteLayers {
    static func empty(style: Style) -> RouteLayers {
        RouteLayers(start: LayerSource(iconId: "route-start", iconImageName: Layers.routeStartIcon, iconSize: 0.04),
                    initial: LayerSource(lineId: "route-initial"),
                    fairways: LayerSource(lineId: "route-fairways"),
                    tail: LayerSource(lineId: "route-tail"),
                    finish: LayerSource(iconId: "route-finish", iconImageName: Layers.routeEndIcon, iconSize: 0.04),
                    style: style)
    }
    
    let start: LayerSource<SymbolLayer>
    let initial: LayerSource<LineLayer>
    let fairways: LayerSource<LineLayer>
    let tail: LayerSource<LineLayer>
    let finish: LayerSource<SymbolLayer>
    let style: Style
    
    init(start: LayerSource<SymbolLayer>, initial: LayerSource<LineLayer>, fairways: LayerSource<LineLayer>, tail: LayerSource<LineLayer>, finish: LayerSource<SymbolLayer>, style: Style) {
        self.start = start
        self.initial = initial
        self.initial.layer.lineDasharray = .constant([2, 4])
        self.fairways = fairways
        self.tail = tail
        self.tail.layer.lineDasharray = .constant([2, 4])
        self.finish = finish
        self.style = style
    }
    
    func update(initial: [CLLocationCoordinate2D], fairways: [CLLocationCoordinate2D], tail: [CLLocationCoordinate2D]) throws {
        let route = initial + fairways + tail
        if let first = route.first {
            try style.updateGeoJSONSource(withId: start.sourceId, geoJSON: .feature(.init(geometry: .point(.init(first)))))
        }
        try update(self.initial, initial)
        try update(self.fairways, fairways)
        try update(self.tail, tail)
        if let last = route.last {
            try style.updateGeoJSONSource(withId: finish.sourceId, geoJSON: .feature(.init(geometry: .point(.init(last)))))
        }
    }
    
    func update(_ src: LayerSource<LineLayer>, _ coords: [CLLocationCoordinate2D]) throws {
        try style.updateGeoJSONSource(withId: src.sourceId, geoJSON: .feature(Feature(geometry: .multiPoint(.init(coords)))))
    }
    
    func install() throws {
        try start.install(to: style, id: start.sourceId)
        try initial.install(to: style, id: initial.sourceId)
        try fairways.install(to: style, id: fairways.sourceId)
        try tail.install(to: style, id: tail.sourceId)
        try finish.install(to: style, id: finish.sourceId)
    }
}

class PathFinder: NSObject, UIGestureRecognizerDelegate {
    let log = LoggerFactory.shared.vc(PathFinder.self)
    
    private let mapView: MapView
    private let style: Style
    
    private let edgePadding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
    
    private var start: CLLocationCoordinate2D? = nil
    private var end: CLLocationCoordinate2D? = nil
    
    private var current: RouteLayers? = nil
    
    init(mapView: MapView, style: Style) {
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
            let coord = mapView.mapboxMap.coordinate(for: point)
            if let _ = start, let end = end {
                self.start = end
                self.end = coord
                shortest(from: end, to: coord)
            } else if let start = start {
                self.end = coord
                shortest(from: start, to: coord)
            } else {
                // TODO render start icon
                self.start = coord
            }
        }
    }
    
    func shortest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        log.info("Loading shortest route from \(from) to \(to)...")
        Task {
            do {
                let route = try await Backend.shared.http.shortestRoute(from: from, to: to)
                log.info("Loaded shortest route from \(from) to \(to).")
                update(route: route)
            } catch {
                log.error("Failed to load shortest route from \(from) to \(to). \(error.describe)")
            }
        }
    }
    
    @MainActor func update(route: RouteResult) {
        let layers = currentLayers()
        let fairwayPath = route.route.links.map { $0.to }
        do {
            try layers.update(initial: [route.from, fairwayPath.first ?? route.to],
                              fairways: fairwayPath,
                              tail: [fairwayPath.last ?? route.from, route.to])
            let coords = fairwayPath + [ route.from, route.to ]
            let camera = mapView.mapboxMap.camera(for: coords, padding: self.edgePadding, bearing: nil, pitch: nil)
            mapView.camera.fly(to: camera, duration: nil, completion: nil)
        } catch {
            log.warn("Failed to update route. \(error)")
        }
    }

    func currentLayers() -> RouteLayers {
        if let current = current {
            return current
        } else {
            let layers = RouteLayers.empty(style: style)
            try? layers.install()
            current = layers
            return layers
        }
    }
    
    func clear() {
        if let current = current {
            [current.initial, current.fairways, current.tail].forEach { layerSource in
                style.removeSourceAndLayer(id: layerSource.layer.id)
            }
        }
        start = nil
        end = nil
        current = nil
    }
}
