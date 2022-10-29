import Foundation
import MapboxMaps

protocol MapViewModelLike: ObservableObject {
    var settings: UserSettings { get }
    var latestToken: UserToken? { get }
    var isProfileButtonHidden: Bool { get }
    var isFollowButtonHidden: Bool { get }
    var styleUri: StyleURI? { get set }
}

class MapViewModel: MapViewModelLike {
    let log = LoggerFactory.shared.vc(MapViewModel.self)
    
    private var backend: Backend { Backend.shared }
    private var socket: BoatSocket { backend.socket }
    private var http: BoatHttpClient { backend.http }
    var settings: UserSettings { UserSettings.shared }
    private var prefs: BoatPrefs { BoatPrefs.shared }
    private var clientConf: ClientConf? { settings.conf }
    
    @Published var latestToken: UserToken? = nil
    
    @Published var isProfileButtonHidden: Bool = true
    @Published var isFollowButtonHidden: Bool = false
    @Published var styleUri: StyleURI? = nil
    
    func prepare() async {
        do {
            let conf = try await http.conf()
            settings.conf = conf
            await update(profileHidden: false)
            let url = conf.map.styleUrl
            await update(style: StyleURI(rawValue: url)!)
//            log.info("Obtained style URI \(styleUri), profile hidden \(isProfileButtonHidden).")
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

class PreviewMapViewModel: MapViewModelLike {
    var settings: UserSettings = UserSettings.shared
    var latestToken: UserToken? = nil
    var isProfileButtonHidden: Bool = false
    var isFollowButtonHidden: Bool = false
    var styleUri: StyleURI? = nil
}
