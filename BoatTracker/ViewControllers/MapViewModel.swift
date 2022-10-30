import Foundation
import MapboxMaps
import Combine

protocol MapViewModelLike: ObservableObject {
    var coordsPublisher: Published<CoordsData?>.Publisher { get }
    var vesselsPublisher: Published<[Vessel]>.Publisher { get }
    var follows: Published<Date>.Publisher { get }
    var settings: UserSettings { get }
    var latestToken: UserToken? { get set }
    var latestTrack: TrackName? { get set }
    var isProfileButtonHidden: Bool { get }
    var isFollowButtonHidden: Bool { get }
    var mapMode: MapMode { get set }
    var styleUri: StyleURI? { get set }
    func toggleFollow()
}

extension MapViewModel: BoatSocketDelegate {
    func onCoords(event: CoordsData) {
        Task {
            await update(coordsData: event)
        }
    }
    
    @MainActor private func update(coordsData: CoordsData) {
        latestTrack = coordsData.from.trackName
        coords = coordsData
    }
}

extension MapViewModel: VesselDelegate {
    func on(vessels: [Vessel]) {
        Task {
            await update(vessels: vessels)
        }
    }
    
    @MainActor private func update(vessels: [Vessel]) {
        self.vessels = vessels
    }
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
    private var isSignedIn: Bool { latestToken != nil }
    @Published var latestTrack: TrackName? = nil
    @Published var isProfileButtonHidden: Bool = true
    @Published var isFollowButtonHidden: Bool = false
    @Published var mapMode: MapMode = .fit
    @Published var styleUri: StyleURI? = nil
    @Published var coords: CoordsData? = nil
    var coordsPublisher: Published<CoordsData?>.Publisher { $coords }
    @Published var vessels: [Vessel] = []
    var vesselsPublisher: Published<[Vessel]>.Publisher { $vessels }
    @Published var follow: Date = Date.now
    var follows: Published<Date>.Publisher { $follow }
    private var cancellable: AnyCancellable? = nil
    
    func prepare() async {
        do {
            let conf = try await http.conf()
            settings.conf = conf
            await update(profileHidden: false)
            let url = conf.map.styleUrl
            await update(style: StyleURI(rawValue: url)!)
        } catch {
            log.error("Failed to load conf and style: '\(error.describe)'.")
        }
        cancellable = Auth.shared.$tokens.sink { token in
            Task {
                await self.reload(token: token)
            }
        }
    }
    
    @MainActor
    func reload(token: UserToken?) async {
        log.info("Reloading with \(token?.email ?? "no user")")
        latestToken = token
        socket.delegate = nil
        socket.close()
        socket.updateToken(token: token?.token)
        socket.delegate = self
        socket.vesselDelegate = self
        socket.open()
        await setupUser(token: token?.token)
    }
    
    func setupUser(token: AccessToken?) async {
        http.updateToken(token: token)
        if isSignedIn {
            do {
                let profile = try await http.profile()
                settings.profile = profile
            } catch {
                log.error("Unable to load profile: '\(error.describe)'.")
            }
        } else {
            settings.profile = nil
        }
    }
    
    @MainActor private func update(style: StyleURI) {
        styleUri = style
    }
    @MainActor private func update(profileHidden: Bool) {
        isProfileButtonHidden = profileHidden
    }
    
    func toggleFollow() {
        follow = Date.now
    }
}

class PreviewMapViewModel: MapViewModelLike {
    @Published var coords: CoordsData? = nil
    @Published var vessels: [Vessel] = []
    var coordsPublisher: Published<CoordsData?>.Publisher { $coords }
    var vesselsPublisher: Published<[Vessel]>.Publisher { $vessels }
    @Published var follow: Date = Date.now
    var follows: Published<Date>.Publisher { $follow }
    var settings: UserSettings = UserSettings.shared
    var latestToken: UserToken? = nil
    var latestTrack: TrackName? = nil
    var mapMode: MapMode = .fit
    var isProfileButtonHidden: Bool = false
    var isFollowButtonHidden: Bool = false
    var styleUri: StyleURI? = nil
    func toggleFollow() { }
}
