import Combine
import Foundation
import MapboxMaps

protocol MapViewModelLike: ObservableObject {
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
  func toggleFollow()
}

extension MapViewModel: BoatSocketDelegate {
  func onCoords(event: CoordsData) {
    Task {
      await update(coordsData: event)
    }
  }

  @MainActor private func update(coordsData: CoordsData) {
    coords = coordsData
    // log.info("Got \(coordsData.coords.count) coords")
  }
}

extension MapViewModel: VesselDelegate {
  func on(vessels: [Vessel]) async {
      await update(vessels: vessels)
  }

  @MainActor private func update(vessels: [Vessel]) {
    self.vessels = vessels
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
  var vesselsPublisher: Published<[Vessel]>.Publisher { $vessels }
  @Published var command: MapCommand? = nil
  var commands: Published<MapCommand?>.Publisher { $command }
  @Published var welcomeInfo: WelcomeInfo? = nil
  @Published var activeTrack = ActiveTrack()
  
  func prepare() async {
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
      await update(style: StyleURI(rawValue: url)!)
    } catch {
      log.error("Failed to load conf and style: '\(error.describe)'.")
    }
  }
  
  @MainActor
  private func update(isConnected: Bool) {
    isFollowButtonHidden = !isConnected
  }

  @MainActor
  func reload(token: UserToken?) async {
    log.info("Reloading with \(token?.email ?? "no user")")
    latestToken = token
    socket.delegate = nil
    socket.close()
    command = .clearAll
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
}

class PreviewMapViewModel: MapViewModelLike {
  @Published var coords: CoordsData? = nil
  var latestTrack: TrackName? { nil }
  @Published var vessels: [Vessel] = []
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
  func toggleFollow() {}
  func onTrack(_ track: TrackName) {}
}
