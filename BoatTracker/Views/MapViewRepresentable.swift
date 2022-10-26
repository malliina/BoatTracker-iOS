import Foundation
import MapboxMaps
import SwiftUI

struct SwiftUIMapView: UIViewRepresentable {
    let log = LoggerFactory.shared.vc(SwiftUIMapView.self)
    @ObservedObject var viewModel: MapViewModel
    
    let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
    let viewFrame: CGRect = CGRect(x: 0, y: 0, width: 64, height: 64)
    
    func makeUIView(context: Context) -> MapView {
        log.info("Make map view")
        let camera = CameraOptions(center: defaultCenter, zoom: 10)
        let token = try! MapVC.readMapboxToken()
        let options = MapInitOptions(resourceOptions: token, cameraOptions: camera, styleURI: nil)
        let mapView = MapView(frame: viewFrame, mapInitOptions: options)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return mapView
    }
    
    func updateUIView(_ uiView: MapView, context: Context) {
        log.info("Update map view, profile hidden \(viewModel.isProfileButtonHidden)")
        context.coordinator.update(view: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(map: self)
    }
    
    class Coordinator {
        let log = LoggerFactory.shared.vc(Coordinator.self)
        private var isStyleLoaded = false
        let map: SwiftUIMapView
        
        init(map: SwiftUIMapView) {
            self.map = map
        }
        
        func update(view: MapView) {
            guard let styleUri = map.viewModel.styleUri, !isStyleLoaded else { return }
            log.info("Loading style \(styleUri)")
            isStyleLoaded = true
            view.mapboxMap.loadStyleURI(styleUri) { result in
                switch result {
                case .success(let style):
                    self.log.info("Style '\(styleUri)' loaded.")
//                    Task {
//                        await self.onStyleLoaded(mapView, didFinishLoading: style)
//                    }
                case let .failure(error):
                    self.log.error("Failed to load style \(styleUri). \(error)")
                }
            }
        }
    }
    
    static func readMapboxToken(key: String = "MapboxAccessToken") throws -> ResourceOptions {
        let token = try Credentials.read(key: key)
//        log.info("Using token \(token)")
        return ResourceOptions(accessToken: token)
    }
}
