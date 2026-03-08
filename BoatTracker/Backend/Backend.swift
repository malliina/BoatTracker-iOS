import Combine
import Foundation

class Backend {
  static let shared = Backend(EnvConf.shared.baseUrl)
  let log = LoggerFactory.shared.system(Backend.self)

  let baseUrl: URL
  private var latestToken: UserToken? = nil

  var http: BoatHttpClient
  let socket: BoatSocket
  let logs: LogsHttpClient

  private var cancellables: [Task<(), Never>] = []

  init(_ baseUrl: URL) {
    self.baseUrl = baseUrl
    let client = HttpClient()
    self.http = BoatHttpClient(
      bearerToken: nil, baseUrl: baseUrl, client: client)
    self.socket = BoatSocket(baseUrl)
    self.logs = LogsHttpClient(baseUrl: EnvConf.shared.logsUrl, client: client)
  }

  func prepare() async {
    let logsListener = Task {
      await logs.listen()
    }
    socket.start()
    let listener = Task {
      for await state in Auth.shared.$authState.values {
        switch state {
        case .authenticated(let token): self.updateToken(new: token)
        case .unauthenticated: self.updateToken(new: nil)
        case .unknown: ()
        }
      }
    }
    cancellables = [listener, logsListener]
  }

  func updateToken() async throws -> UserToken? {
    let token = try await Auth.shared.signInSilently()
    updateToken(new: token)
    return token
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
