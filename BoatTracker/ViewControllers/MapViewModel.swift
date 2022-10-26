import Foundation
import MapboxMaps

class MapViewModel: ObservableObject {
    let log = LoggerFactory.shared.vc(MapViewModel.self)
    
    private var backend: Backend { Backend.shared }
    private var socket: BoatSocket { backend.socket }
    private var http: BoatHttpClient { backend.http }
    private var settings: UserSettings { UserSettings.shared }
    private var prefs: BoatPrefs { BoatPrefs.shared }
    private var clientConf: ClientConf? { settings.conf }
    
    @Published var isProfileButtonHidden: Bool = true
    @Published var styleUri: StyleURI? = nil
    
    func prepare() async {
        do {
            let conf = try await http.conf()
            settings.conf = conf
            await update(profileHidden: false)
            let url = conf.map.styleUrl
            await update(style: StyleURI(rawValue: url)!)
            
//            mapView.mapboxMap.loadStyleURI(StyleURI(rawValue: url)!) { result in
//                switch result {
//                case .success(let style):
//                    self.log.info("Style '\(url)' loaded.")
//                    Task {
//                        await self.onStyleLoaded(mapView, didFinishLoading: style)
//                    }
//                case let .failure(error):
//                    self.log.error("Failed to load style \(url). \(error)")
//                }
//            }
        } catch {
            log.error("Failed to load conf and style: '\(error.describe)'.")
        }
    }
    
    @MainActor private func update(style: StyleURI) {
        styleUri = style
    }
    @MainActor private func update(profileHidden: Bool) {
        isProfileButtonHidden = profileHidden
    }
}
