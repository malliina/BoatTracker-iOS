import Foundation
import MapboxMaps
import SwiftUI
import Combine

struct MapViewRepresentable: UIViewRepresentable {
    static let logger = LoggerFactory.shared.vc(MapViewRepresentable.self)
    var log: Logger { MapViewRepresentable.logger }
    
    @Binding var styleUri: StyleURI?
    @Binding var tapped: Tapped?
    @Binding var mapMode: MapMode
    let coords: Published<CoordsData?>.Publisher
    let vessels: Published<[Vessel]>.Publisher
    let commands: Published<MapCommand?>.Publisher
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    let viewFrame: CGRect = CGRect(x: 0, y: 0, width: 64, height: 64)
    
    func makeUIView(context: Context) -> MapView {
        let camera = CameraOptions(center: defaultCenter, zoom: 10)
        let token = try! MapViewRepresentable.readMapboxToken()
        let options = MapInitOptions(resourceOptions: token, cameraOptions: camera, styleURI: nil)
        let mapView = MapView(frame: viewFrame, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        if let styleUri = styleUri, !uiView.mapboxMap.style.isLoaded, !context.coordinator.isStyleLoaded {
            context.coordinator.isStyleLoaded = true
            log.info("Loading style at \(styleUri.rawValue)...")
            Task {
                do {
                    let style = try await loadStyle(map: uiView, uri: styleUri)
                    log.info("Style '\(styleUri.rawValue)' loaded.")
                    await context.coordinator.onStyleLoaded(uiView, didFinishLoading: style)
                } catch {
                    log.error("Failed to load style \(styleUri.rawValue). \(error)")
                }
            }
        }
    }
    
    @MainActor
    private func loadStyle(map: MapView, uri: StyleURI) async throws -> Style {
        try await withUnsafeThrowingContinuation { cont in
            map.mapboxMap.loadStyleURI(uri) { result in
                switch result {
                case .success(let style): cont.resume(returning: style)
                case let .failure(error): cont.resume(throwing: error)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(map: self) }
    
    class Coordinator: NSObject, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate {
        let log = LoggerFactory.shared.vc(Coordinator.self)
        var isStyleLoaded = false
        let map: MapViewRepresentable
        
        private var style: Style? = nil
        private var boatRenderer: BoatRenderer? = nil
        private var pathFinder: PathFinder? = nil
        private var aisRenderer: AISRenderer? = nil
        private var taps: TapListener? = nil
        private var settings: UserSettings { UserSettings.shared }
        private var firstInit: Bool = true
        private var cancellable: AnyCancellable? = nil
        private var vesselJob: AnyCancellable? = nil
        private var followJob: AnyCancellable? = nil
        
        init(map: MapViewRepresentable) {
            self.map = map
        }
        
        func onStyleLoaded(_ mapView: MapView, didFinishLoading style: Style) async {
            self.style = style
            let boats = BoatRenderer(mapView: mapView, style: style, mapMode: map._mapMode)
            log.info("Subscribing to coords events...")
            cancellable = map.coords.sink { coords in
                if let coords = coords {
                    do {
                        self.log.info("Handling event with \(coords.coords.count) coords...")
                        try boats.addCoords(event: coords)
                    } catch {
                        self.log.error("Failed to handle coords. \(error)")
                    }
                }
            }
            
            boatRenderer = boats
            let paths = PathFinder(mapView: mapView, style: style)
            pathFinder = paths
            followJob = map.commands.sink { cmd in
                if let cmd = cmd {
                    switch cmd {
                    case .toggleFollow:
                        boats.toggleFollow()
                    case .clearAll:
                        boats.clear()
                        paths.clear()
                    }
                }
            }
            installTapListener(mapView: mapView)
            guard let conf = settings.conf else { return }
            // Maybe the conf should be cached in a file?
            await initInteractive(mapView: mapView, style: style, layers: conf.layers, boats: boats)
            
            let swipes = UIPanGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
            // Prevents this from firing when the user is zooming
            swipes.maximumNumberOfTouches = 1
            swipes.delegate = self
            mapView.addGestureRecognizer(swipes)
        }
        
        @objc func onSwipe(_ sender: UIPanGestureRecognizer) {
            map.tapped = nil
            if sender.state == .began {
                boatRenderer?.stay()
            }
        }
        
        func initInteractive(mapView: MapView, style: Style, layers: MapboxLayers, boats: BoatRenderer) async {
            if firstInit {
                firstInit = false
                if BoatPrefs.shared.isAisEnabled {
                    do {
                        let ais = try AISRenderer(mapView: mapView, style: style, conf: layers.ais)
                        vesselJob = map.vessels.sink { vs in
                            do {
                                try ais.update(vessels: vs)
                            } catch {
                                self.log.error("Failed to update AIS. \(error)")
                            }
                        }
                        aisRenderer = ais
                    } catch {
                        log.warn("Failed to init AIS. \(error)")
                    }
                }
                taps = TapListener(mapView: mapView, layers: layers, ais: aisRenderer, boats: boats)
            }
        }
        
        func installTapListener(mapView: MapView) {
            mapView.gestures.singleTapGestureRecognizer.addTarget(self, action: #selector(handleMapTap(sender:)))
            mapView.gestures.singleTapGestureRecognizer.require(toFail: mapView.gestures.doubleTapToZoomInGestureRecognizer)
        }
        
        @objc func handleMapTap(sender: UITapGestureRecognizer) {
            log.info("Tapped map...")
            let point = sender.location(in: sender.view)
            if sender.state == .ended {
                Task {
                    await handlePopover(sender: sender, point: point)
                }
            }
        }
        
        @MainActor
        private func handlePopover(sender: UITapGestureRecognizer, point: CGPoint) async {
            // Tries matching the exact point first
            guard let senderView = sender.view, let taps = taps else { return }
            if let tapResult = await taps.onTap(point: point) {
                map.tapped = Tapped(source: senderView, point: extractPoint(result: tapResult) ?? point, result: tapResult)
//                log.info("Tapped \(tapped) at \(tapped.coordinate).")
            } else {
                log.info("Tapped nothing of interest.")
                map.tapped = nil
            }
        }
        
        private func extractPoint(result: TapResult) -> CGPoint? {
            switch result {
            case .mark(_, let point, _): return point
            default: return nil
            }
        }
        
        /// Essential to make the popup show as a popup and not as a near-full-page sheet on iOS
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            .none
        }
        
        /// UIGestureRecognizerDelegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
    
    static func readMapboxToken(key: String = "MapboxAccessToken") throws -> ResourceOptions {
        let token = try Credentials.read(key: key)
//        MapViewRepresentable.logger.info("Using token \(token)")
        return ResourceOptions(accessToken: token)
    }
}
