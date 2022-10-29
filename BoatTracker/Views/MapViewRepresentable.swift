import Foundation
import MapboxMaps
import SwiftUI
import Combine

struct MapViewRepresentable: UIViewRepresentable {
    let log = LoggerFactory.shared.vc(MapViewRepresentable.self)
    
    @Binding var styleUri: StyleURI?
    @Binding var latestTrack: TrackName?
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    let viewFrame: CGRect = CGRect(x: 0, y: 0, width: 64, height: 64)
    
    func makeUIView(context: Context) -> MapView {
        log.info("Making map.")
        let camera = CameraOptions(center: defaultCenter, zoom: 10)
        let token = try! MapVC.readMapboxToken()
        let options = MapInitOptions(resourceOptions: token, cameraOptions: camera, styleURI: nil)
        let mapView = MapView(frame: viewFrame, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        if let styleUri = styleUri, !uiView.mapboxMap.style.isLoaded, !context.coordinator.isStyleLoaded {
            context.coordinator.isStyleLoaded = true
            log.info("Loading style.")
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
    
    class Coordinator {
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
        
        init(map: MapViewRepresentable) {
            self.map = map
        }
        
        func update(view: MapView) {
            guard let styleUri = map.styleUri, !isStyleLoaded else {
                log.info("Style loaded \(isStyleLoaded), returning")
                return
            }
            log.info("Loading style \(styleUri)")
            isStyleLoaded = true
            view.mapboxMap.loadStyleURI(styleUri) { result in
                switch result {
                case .success(let style):
                    self.log.info("Style '\(styleUri.rawValue)' loaded.")
                    Task {
                        await self.onStyleLoaded(view, didFinishLoading: style)
                    }
                case let .failure(error):
                    self.log.error("Failed to load style \(styleUri). \(error)")
                }
            }
        }
        
        func onStyleLoaded(_ mapView: MapView, didFinishLoading style: Style) async {
            self.style = style
            let boats = BoatRenderer(mapView: mapView, style: style)
            boatRenderer = boats
            pathFinder = await PathFinder(mapView: mapView, style: style)
            installTapListener(mapView: mapView)
            guard let conf = settings.conf else { return }
            // Maybe the conf should be cached in a file?
            await initInteractive(mapView: mapView, style: style, layers: conf.layers, boats: boats)
        }
        
        func initInteractive(mapView: MapView, style: Style, layers: MapboxLayers, boats: BoatRenderer) async {
            if firstInit {
                firstInit = false
                if BoatPrefs.shared.isAisEnabled {
                    do {
                        let ais = try AISRenderer(mapView: mapView, style: style, conf: layers.ais)
                        self.aisRenderer = ais
                    } catch {
                        log.warn("Failed to init AIS. \(error)")
                    }
                }
                self.taps = TapListener(mapView: mapView, layers: layers, ais: self.aisRenderer, boats: boats)
//                cancellable = Auth.shared.$tokens.sink { token in
//                    Task {
//                        await self.reload(token: token)
//                    }
//                }
            }
        }
        
        func installTapListener(mapView: MapView) {
            mapView.gestures.singleTapGestureRecognizer.addTarget(self, action: #selector(handleMapTap(sender:)))
            mapView.gestures.singleTapGestureRecognizer.require(toFail: mapView.gestures.doubleTapToZoomInGestureRecognizer)
        }
        
        @objc func handleMapTap(sender: UITapGestureRecognizer) {
            if sender.state == .ended {
                // Tries matching the exact point first
                guard let senderView = sender.view, let taps = taps else { return }
                let point = sender.location(in: senderView)
                Task {
                    if let tapped = await taps.onTap(point: point) {
                        // self.log.info("Tapped \(tapped) at \(tapped.coordinate).")
                        guard let popoverContent = popoverView(tapped) else { return }
                        log.info("Display popover")
//                        displayDetails(child: popoverContent, senderView: senderView, point: point)
                    } else {
                        self.log.info("Tapped nothing of interest.")
//                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
        
        private func popoverView(_ tapped: CustomAnnotation) -> UIView? {
            guard let lang = settings.lang, let finnishSpecials = settings.languages?.finnish.specialWords else { return nil }
            return tapped.callout(lang: lang, finnishSpecials: finnishSpecials)
        }
    }
    
    static func readMapboxToken(key: String = "MapboxAccessToken") throws -> ResourceOptions {
        let token = try Credentials.read(key: key)
//        log.info("Using token \(token)")
        return ResourceOptions(accessToken: token)
    }
}
