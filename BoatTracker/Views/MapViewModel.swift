import Combine
import Foundation
import MapboxMaps
import Algorithms

protocol MapViewModelLike: ObservableObject {
  var vessels: [Vessel] { get }
  var allVessels: [Vessel] { get }
  var tracks: [CoordsData] { get }
  var latestTrackPoints: [SingleTrackPoint] { get }
  var coordsPublisher: Published<CoordsData?>.Publisher { get }
  var latestTrack: TrackName? { get }
  var vesselsPublisher: Published<[Vessel]>.Publisher { get }
  var commands: Published<MapCommand?>.Publisher { get }
  var settings: UserSettings { get }
  var latestToken: UserToken? { get set }
  var isProfileButtonHidden: Bool { get }
  var isFollowButtonHidden: Bool { get }
  var mapMode: MapMode { get set }
  var styleUri: StyleURI? { get set }
  var activeTrack: ActiveTrack { get }
  // result from shortest path goes here
  var routeResult: RouteResult? { get set }
  
  func shortest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D)
  func toggleFollow()
  func vesselInfo(_ mmsi: Mmsi) -> Vessel?
}

extension MapViewModel: BoatSocketDelegate {
  func onCoords(event: CoordsData) {
    Task {
      await update(coordsData: event)
    }
  }

  @MainActor private func update(coordsData: CoordsData) {
    coords = coordsData
    var modified = tracks
    let idx = modified.indexOf { data in
      data.from.trackName == coordsData.from.trackName
    }
    if let idx = idx {
      modified[idx] = CoordsData(coords: modified[idx].coords + coordsData.coords, from: coordsData.from)
    } else {
      modified.append(coordsData)
    }
    tracks = modified
    log.info("Got \(coordsData.coords.count) coords, tracks now has \(tracks.count) elements")
  }
}

extension MapViewModel: VesselDelegate {
  func on(vessels: [Vessel]) async {
    await update(vessels: vessels)
  }

  @MainActor private func update(vessels: [Vessel]) {
    AISState.shared.update(vessels: vessels)
    self.vessels = vessels
    self.allVessels = (self.allVessels + vessels).uniqued { vessel in
      vessel.mmsi
    }
  }
}

class MapViewModel: MapViewModelLike {
  let log = LoggerFactory.shared.vc(MapViewModel.self)

  private var socket: BoatSocket { backend.socket }
  private var clientConf: ClientConf? { settings.conf }

  @Published var latestToken: UserToken? = nil
  private var isSignedIn: Bool { latestToken != nil }
  @Published var isProfileButtonHidden: Bool = true
  @Published var isFollowButtonHidden: Bool = false
  @Published var mapMode: MapMode = .fit
  @Published var styleUri: StyleURI? = nil
  @Published var coords: CoordsData? = nil
  @Published var selectedTrack: TrackName? = nil
  var latestTrack: TrackName? {
    coords?.from.trackName
  }
  var coordsPublisher: Published<CoordsData?>.Publisher { $coords }
  @Published var vessels: [Vessel] = []
  @Published var allVessels: [Vessel] = []
  var vesselsPublisher: Published<[Vessel]>.Publisher { $vessels }
  @Published var command: MapCommand? = nil
  var commands: Published<MapCommand?>.Publisher { $command }
  @Published var welcomeInfo: WelcomeInfo? = nil
  @Published var activeTrack = ActiveTrack()
  
  @Published var tracks: [CoordsData] = []
  var latestTrackPoints: [SingleTrackPoint] { 
    tracks.compactMap { cd in
      if let last = cd.coords.last, let bearing = MapViewModel.adjustedBearing(data: cd) {
        SingleTrackPoint(from: cd.from, point: last, bearing: bearing)
      } else {
        nil
      }
    }.reversed().uniqued { stp in
      stp.from.boatName
    }
  }
  @Published var routeResult: RouteResult? = nil
  
  static let defaultCenter = CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9)
  
  static func adjustedBearing(data: CoordsData) -> CLLocationDirection? {
    let lastTwo = Array(data.coords.suffix(2)).map { $0.coord }
    let bearing = lastTwo.count == 2 ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
    if let bearing = bearing {
      return data.from.sourceType.isBoat ? bearing : (bearing + 90).truncatingRemainder(dividingBy: 360)
    }
    return nil
  }
  
  func prepare() async {
    do {
      let token = try Credentials.read(key: "MapboxAccessToken")
      MapboxOptions.accessToken = token
    } catch {
      log.info("Failed to read Mapbox token from credentials file. \(error)")
    }
    Task {
      for await state in Auth.shared.$authState.values {
        switch state {
        case .authenticated(let token):
          self.log.info("Got user '\(token.email)'.")
          await self.reload(token: token)
        case .unauthenticated:
          self.log.info("Got no user.")
          await self.reload(token: nil)
        case .unknown:
          self.log.info("Waiting for proper auth state...")
        }
      }
    }
    Task {
      for await track in activeTrack.$selectedTrack.map({ $0?.track }).removeDuplicates().values {
        log.info("Changed to \(track?.name ?? "no track").")
        await change(to: track)
      }
    }
    Task {
      for await isConnected in backend.socket.$isConnected.removeDuplicates().values {
        await update(isConnected: isConnected)
      }
    }
    do {
      let conf = try await http.conf()
      settings.conf = conf
      await update(profileHidden: false)
      let url = conf.map.styleUrl
      log.info("Using style '\(url)'...")
      await update(style: StyleURI(rawValue: url)!)
    } catch {
      log.error("Failed to load conf and style: '\(error.describe)'.")
    }
  }
  
  func shortest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
    log.info("Loading shortest route from \(from) to \(to)...")
    Task {
      do {
        let route = try await Backend.shared.http.shortestRoute(from: from, to: to)
        log.info("Loaded shortest route from \(from) to \(to).")
        await update(route: route)
      } catch {
        log.error("Failed to load shortest route from \(from) to \(to). \(error.describe)")
      }
    }
  }
  
  @MainActor private func update(route: RouteResult) {
    routeResult = route
  }
  
  @MainActor
  private func update(isConnected: Bool) {
    isFollowButtonHidden = !isConnected
  }

  @MainActor
  func reload(token: UserToken?) async {
    log.info("Reloading with \(token?.email ?? "no user")")
    latestToken = token
    disconnect()
    allVessels = []
    socket.updateToken(token: token?.token)
    socket.delegate = self
    socket.vesselDelegate = self
    socket.reconnect(token: token?.token, track: nil) // is nil correct?
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

  private func change(to track: TrackName?) async {
    await disconnect()
    //log.info("Changing to \(track)...")
    backend.open(track: track, delegate: self)
  }

  @MainActor private func disconnect() {
    socket.delegate = nil
    socket.close()
    command = .clearAll
    tracks = []
    coords = nil
    routeResult = nil
  }

  @MainActor private func update(style: StyleURI) {
    styleUri = style
  }
  @MainActor private func update(profileHidden: Bool) {
    isProfileButtonHidden = profileHidden
  }

  @MainActor func toggleFollow() {
    command = .toggleFollow
  }
  
  func vesselInfo(_ mmsi: Mmsi) -> Vessel? {
    AISState.shared.info(mmsi)
  }
}

class PreviewMapViewModel: MapViewModelLike {
  @Published var coords: CoordsData? = nil
  var latestTrack: TrackName? { nil }
  @Published var vessels: [Vessel] = []
  var allVessels: [Vessel] = []
  var tracks: [CoordsData] = []
  var latestTrackPoints: [SingleTrackPoint] = []
  var coordsPublisher: Published<CoordsData?>.Publisher { $coords }
  var vesselsPublisher: Published<[Vessel]>.Publisher { $vessels }
  @Published var command: MapCommand? = nil
  var commands: Published<MapCommand?>.Publisher { $command }
  var settings: UserSettings = UserSettings.shared
  var latestToken: UserToken? = nil
  var mapMode: MapMode = .fit
  var isProfileButtonHidden: Bool = false
  var isFollowButtonHidden: Bool = false
  var styleUri: StyleURI? = nil
  var activeTrack: ActiveTrack = ActiveTrack()
  var routeResult: RouteResult? = nil
  func shortest(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {}
  func toggleFollow() {}
  func onTrack(_ track: TrackName) {}
  func vesselInfo(_ mmsi: Mmsi) -> Vessel? { nil }
}
