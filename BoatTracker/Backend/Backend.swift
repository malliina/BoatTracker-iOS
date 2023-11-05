import Combine
import Foundation

class Backend {
  static let shared = Backend(EnvConf.shared.baseUrl)
  let log = LoggerFactory.shared.system(Backend.self)

  let baseUrl: URL
  private var latestToken: UserToken? = nil

  var http: BoatHttpClient
  var socket: BoatSocket
  private var cancellable: AnyCancellable? = nil

  init(_ baseUrl: URL) {
    self.baseUrl = baseUrl
    self.http = BoatHttpClient(bearerToken: nil, baseUrl: baseUrl, client: HttpClient())
    self.socket = BoatSocket(token: nil, track: nil)
    cancellable = Auth.shared.$tokens.sink { state in
      switch state {
      case .authenticated(let token): self.updateToken(new: token)
      case .unauthenticated: self.updateToken(new: nil)
      case .unknown: ()
      }
    }
  }

  private func updateToken(new token: UserToken?) {
    latestToken = token
    http.updateToken(token: token?.token)
    socket.updateToken(token: token?.token)
    let keychain = Keychain.shared
    do {
      if let token = token?.token {
        try keychain.use(token: token)
      } else {
        try keychain.delete()
      }
    } catch {
      log.error("Keychain failure. \(error)")
    }
  }

  func open(track: TrackName?, delegate: BoatSocketDelegate) {
    socket.delegate = nil
    socket.close()
    socket = openStandalone(track: track, delegate: delegate)
  }

  func openStandalone(track: TrackName?, delegate: BoatSocketDelegate) -> BoatSocket {
    let s = BoatSocket(token: latestToken?.token, track: track)
    s.delegate = delegate
    // log.info("Opening standalone...")
    s.open()
    return s
  }
}
