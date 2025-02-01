import Combine
import Foundation

class Backend {
  static let shared = Backend(EnvConf.shared.baseUrl)
  let log = LoggerFactory.shared.system(Backend.self)

  let baseUrl: URL
  private var latestToken: UserToken? = nil

  var http: BoatHttpClient
  let socket: BoatSocket

  private var cancellables: [Task<(), Never>] = []
  
  init(_ baseUrl: URL) {
    self.baseUrl = baseUrl
    self.http = BoatHttpClient(
      bearerToken: nil, baseUrl: baseUrl, client: HttpClient())
    self.socket = BoatSocket(baseUrl)
  }

  func prepare() async {
    let listener = Task {
      for await state in Auth.shared.$authState.values {
        switch state {
        case .authenticated(let token): self.updateToken(new: token)
        case .unauthenticated: self.updateToken(new: nil)
        case .unknown: ()
        }
      }
    }
    cancellables = [listener]
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

  func open(track: TrackName?) {
    socket.reconnect(token: latestToken?.token, track: track)
  }

  func openStandalone(track: TrackName?)
    -> BoatSocket
  {
    let s = BoatSocket(baseUrl)
    s.reconnect(token: latestToken?.token, track: track)
    return s
  }
}
