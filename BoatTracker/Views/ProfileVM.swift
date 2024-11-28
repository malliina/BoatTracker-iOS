import Foundation

protocol ProfileProtocol: ObservableObject {
  var state: ViewState { get }
  var summary: TrackRef? { get }
  func versionText(lang: Lang) -> String?
  func loadTracks(latest: TrackName?) async
  func disconnect()
  func signOut(from: UIViewController) async
  func deleteMe(from: UIViewController) async -> Bool
}

class ProfileVM: ProfileProtocol {
  let log = LoggerFactory.shared.vc(ProfileVM.self)

  @Published var state: ViewState = .idle
  @Published var tracks: [TrackRef] = []
  @Published var current: TrackName? = nil
  
  var summary: TrackRef? = nil
  
  private var summaryFromList: TrackRef? {
    tracks.first { ref in
      ref.trackName == current
    }
  }

  private var socket: BoatSocket? = nil
  private var cancellables: [Task<(), Never>] = []
    
  func connect(track: TrackName) {
    let s = Backend.shared.openStandalone(track: track)
    socket = s
    let t = Task {
      for await coords in s.updates.values {
        await update(ref: coords.from)
      }
    }
    cancellables = [t]
  }
  
  func disconnect() {
    socket?.close()
    socket = nil
    cancellables.forEach { t in
      t.cancel()
    }
    cancellables = []
  }

  func versionText(lang: Lang) -> String? {
    if let bundleMeta = Bundle.main.infoDictionary,
      let appVersion = bundleMeta["CFBundleShortVersionString"] as? String,
      let buildId = bundleMeta["CFBundleVersion"] as? String
    {
      return "\(lang.appMeta.version) \(appVersion) \(lang.appMeta.build) \(buildId)"
    } else {
      return nil
    }
  }

  func loadTracks(latest: TrackName?) async {
    await update(viewState: .loading)
    do {
      let ts = try await http.tracks(limit: 10, offset: 0)
      log.info("Got \(ts.count) tracks.")
      await update(ts: ts, trackName: latest)
      if let latest = latest {
        connect(track: latest)
      }
    } catch {
      log.error("Unable to load tracks. \(error.describe)")
      await update(viewState: .failed)
    }
  }

  func signOut(from: UIViewController) async {
    log.info("Signing out...")
    await Auth.shared.signOut(from: from)
  }

  func deleteMe(from: UIViewController) async -> Bool {
    do {
      _ = try await http.deleteMe()
      log.info("Deleted user.")
      await signOut(from: from)
      return true
    } catch {
      log.error("Failed to delete user. \(error)")
      return false
    }

  }

  @MainActor private func update(ref: TrackRef) {
    summary = ref
  }
  
  @MainActor private func update(viewState: ViewState) {
    state = viewState
  }

  @MainActor private func update(ts: [TrackRef], trackName: TrackName?) {
    tracks = ts
    current = trackName
    state = ts.isEmpty ? .empty : .content
    summary = ts.first { ref in
      ref.trackName == trackName
    }
  }

  @MainActor private func update(err: Error) {
    state = .failed
  }
}
