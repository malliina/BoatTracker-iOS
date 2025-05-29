import Algorithms
import Combine
import Foundation
import MapboxMaps

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
  func toggleFollow() async
  func vesselInfo(_ mmsi: Mmsi) -> Vessel?
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
      if let last = cd.coords.last,
        let bearing = MapViewModel.adjustedBearing(data: cd)
      {
        SingleTrackPoint(from: cd.from, point: last, bearing: bearing)
      } else {
        nil
      }
    }.reversed().uniqued { stp in
      stp.from.boatName
    }
  }
  @Published var routeResult: RouteResult? = nil

  static let defaultCenter = CLLocationCoordinate2D(
    latitude: 60.14, longitude: 24.9)

  private var cancellables: [Task<(), Never>] = []

  static func adjustedBearing(data: CoordsData) -> CLLocationDirection? {
    let lastTwo = Array(data.coords.suffix(2)).map { $0.coord }
    let bearing =
      lastTwo.count == 2
      ? Geo.shared.bearing(from: lastTwo[0], to: lastTwo[1]) : nil
    if let bearing = bearing {
      return data.from.sourceType.isBoat
        ? bearing : (bearing + 90).truncatingRemainder(dividingBy: 360)
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
      for await track in activeTrack.$selectedTrack.map({ $0?.track })
        .removeDuplicates().values
      {
        log.info("Changed to \(track?.name ?? "no track").")
        await change(to: track)
      }
    }
    Task {
      for await isConnected in backend.socket.$isConnected.removeDuplicates()
        .values
      {
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
        let route = try await http.shortestRoute(from: from, to: to)
        log.info("Loaded shortest route from \(from) to \(to).")
        await update(route: route)
      } catch {
        log.error(
          "Failed to load shortest route from \(from) to \(to). \(error.describe)"
        )
      }
    }
  }

  @MainActor private func update(route: RouteResult) {
    routeResult = route
  }

  func reload(token: UserToken?) async {
    log.info("Reloading with \(token?.email ?? "no user")")
    await update(token: token)
    await disconnect()
    await update(allVessels: [])
    socket.updateToken(token: token?.token)
    cancellables = [
      Task {
        for await cd in socket.updates.values {
          await update(coordsData: cd)
        }
      },
      Task {
        for await vs in socket.vesselUpdates.values {
          await update(vessels: vs)
        }
      },
    ]
    socket.reconnect(token: token?.token, track: nil)  // is nil correct?
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
    backend.open(track: track)
  }

  private func disconnect() async {
    cancellables.forEach { c in
      c.cancel()
    }
    cancellables = []
    socket.close()
    await update(command: .clearAll)
    await update(tracks: [])
    await update(coords: nil)
    await update(route: nil)
  }

  @MainActor private func update(coordsData: CoordsData) {
    coords = coordsData
    var modified = tracks
    let idx = modified.indexOf { data in
      data.from.trackName == coordsData.from.trackName
    }
    if let idx = idx {
      modified[idx] = CoordsData(
        coords: modified[idx].coords + coordsData.coords, from: coordsData.from)
    } else {
      modified.append(coordsData)
    }
    tracks = modified
    log.info(
      "Got \(coordsData.coords.count) coords, tracks now has \(tracks.count) elements"
    )
  }

  @MainActor private func update(vessels: [Vessel]) {
    AISState.shared.update(vessels: vessels)
    self.vessels = vessels
    self.allVessels = (self.allVessels + vessels).uniqued { vessel in
      vessel.mmsi
    }
  }
  @MainActor private func update(allVessels: [Vessel]) {
    self.allVessels = allVessels
  }
  @MainActor private func update(coords: CoordsData?) {
    self.coords = coords
  }
  @MainActor private func update(tracks: [CoordsData]) {
    self.tracks = tracks
  }
  @MainActor private func update(style: StyleURI) {
    styleUri = style
  }
  @MainActor private func update(command: MapCommand) {
    self.command = command
  }
  @MainActor private func update(profileHidden: Bool) {
    isProfileButtonHidden = profileHidden
  }
  @MainActor func update(token: UserToken?) {
    self.latestToken = token
  }
  @MainActor func toggleFollow() async {
    update(command: .toggleFollow)
  }
  @MainActor private func update(route: RouteResult?) {
    routeResult = route
  }
  @MainActor private func update(isConnected: Bool) {
    isFollowButtonHidden = !isConnected
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
