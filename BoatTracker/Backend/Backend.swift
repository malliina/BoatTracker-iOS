import Foundation
import Combine

class Backend {
    static let shared = Backend(EnvConf.shared.baseUrl)
    let log = LoggerFactory.shared.system(Backend.self)
    
    let baseUrl: URL
    private var latestToken: UserToken? = nil
    
    var http: BoatHttpClient
    var socket: BoatSocket
    private var cancellable: AnyCancellable? = nil
    
    init(_ baseUrl: URL) {
        //Logging.URLRequests = { _ in false }
        self.baseUrl = baseUrl
        self.http = BoatHttpClient(bearerToken: nil, baseUrl: baseUrl, client: HttpClient())
        self.socket = BoatSocket(token: nil, track: nil)
        cancellable = Auth.shared.$tokens.sink { token in
            self.updateToken(new: token)
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
    
    func open(track: TrackName, delegate: BoatSocketDelegate) {
        socket.delegate = nil
        socket.close()
        socket = openStandalone(track: track, delegate: delegate)
    }
    
    func openStandalone(track: TrackName, delegate: BoatSocketDelegate) -> BoatSocket {
        let s = BoatSocket(token: latestToken?.token, track: track)
        s.delegate = delegate
        s.open()
        return s
    }
}
