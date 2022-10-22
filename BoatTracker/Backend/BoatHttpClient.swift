import Foundation
import MapboxMaps

class BoatHttpClient {
    private let log = LoggerFactory.shared.network(BoatHttpClient.self)
    
    static let BoatVersion = "application/vnd.boat.v2+json"
    
    let baseUrl: URL
    let client: HttpClient
    
    private var defaultHeaders: [String: String]
    private let postSpecificHeaders: [String: String]
    
    var postHeaders: [String: String] { defaultHeaders.merging(postSpecificHeaders)  { (current, _) in current } }
    
    convenience init(bearerToken: AccessToken, baseUrl: URL, language: Language) {
        self.init(bearerToken: bearerToken, baseUrl: baseUrl, client: HttpClient())
    }
    
    init(bearerToken: AccessToken?, baseUrl: URL, client: HttpClient) {
        self.baseUrl = baseUrl
        self.client = client
        if let token = bearerToken {
            self.defaultHeaders = [
                Headers.authorization: BoatHttpClient.authValue(for: token),
                Headers.accept: BoatHttpClient.BoatVersion,
            ]
        } else {
            self.defaultHeaders = [
                Headers.accept: BoatHttpClient.BoatVersion,
            ]
        }
        self.postSpecificHeaders = [
            Headers.contentType: HttpClient.json
        ]
    }
    
    func updateToken(token: AccessToken?) {
        if let token = token {
            self.defaultHeaders.updateValue(BoatHttpClient.authValue(for: token), forKey: Headers.authorization)
        } else {
            self.defaultHeaders.removeValue(forKey: Headers.authorization)
        }
    }
    
    static func authValue(for token: AccessToken) -> String {
        "bearer \(token.token)"
    }
    
    func pingAuth() async throws -> BackendInfo {
        try await getParsed(BackendInfo.self, "/pingAuth")
    }
    
    // Call after UI sign in completes
    func register(code: RegisterCode) async throws -> TokenResponse {
        try await parsed(TokenResponse.self, "/users/me") { url in
            try await self.client.postJSON(url, payload: code)
        }
    }
    
    // Call on app startup
    func obtainValidToken(token: AccessToken) async throws -> TokenResponse {
        updateToken(token: token)
        return try await parsed(TokenResponse.self, "/users/me/tokens") { url in
            try await self.client.postEmpty(url, headers: self.postHeaders)
        }
    }
    
    func profile() async throws -> UserProfile {
        let parsed = try await getParsed(UserContainer.self, "/users/me")
        return parsed.user
    }
    
    func tracks() async throws -> [TrackRef] {
        let res = try await getParsed(TracksResponse.self, "/tracks")
        return res.tracks
    }
    
    func stats() async throws -> StatsResponse {
        try await getParsed(StatsResponse.self, "/stats?order=desc")
    }
    
    func changeTrackTitle(name: TrackName, title: TrackTitle) async throws -> TrackResponse {
        try await parsed(TrackResponse.self, "/tracks/\(name)") { url in
            try await self.client.putJSON(url, headers: self.postHeaders, payload: ChangeTrackTitle(title: title))
        }
    }
    
    func conf() async throws -> ClientConf {
        try await getParsed(ClientConf.self, "/conf")
    }
    
    func enableNotifications(token: PushToken) async throws -> SimpleMessage {
        try await parsed(SimpleMessage.self, "/users/notifications") { url in
            try await self.client.postJSON(url, headers: self.postHeaders, payload: PushPayload(token))
        }
    }
    
    func disableNotifications(token: PushToken) async throws -> SimpleMessage {
        try await parsed(SimpleMessage.self, "/users/notifications/disable") { url in
            try await self.client.postJSON(url, headers: self.postHeaders, payload: DisablePush(token: token))
        }
    }
    
    func renameBoat(boat: Int, newName: BoatName) async throws -> Boat {
        let res = try await parsed(BoatResponse.self, "/boats/\(boat)") { url in
            try await self.client.patchJSON(url, headers: self.postHeaders, payload: ChangeBoatName(boatName: newName))
        }
        return res.boat
    }
    
    func changeLanguage(to: Language) async throws -> SimpleMessage {
        try await parsed(SimpleMessage.self, "/users/me", run: { url in
            try await self.client.putJSON(url, headers: self.postHeaders, payload: ChangeLanguage(language: to))
        })
    }
    
    func shortestRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> RouteResult {
        try await getParsed(RouteResult.self, "/routes/\(from.latitude)/\(from.longitude)/\(to.latitude)/\(to.longitude)")
    }
    
    func getParsed<T: Decodable>(_ t: T.Type, _ uri: String) async throws -> T {
        try await parsed(t, uri) { url in
            try await self.client.get(url, headers: self.defaultHeaders)
        }
    }
    
    func parsed<T : Decodable>(_ t: T.Type, _ uri: String, run: @escaping (URL) async throws -> HttpResponse, attempt: Int = 1) async throws -> T {
        let url = fullUrl(to: uri)
        let response = try await run(url)
        if response.isStatusOK {
            return try parseAs(t, response: response)
        } else {
            self.log.error("Request to '\(url)' failed with status '\(response.statusCode)'.")
            if attempt == 1 && response.isTokenExpired {
                let token = try await Auth.shared.signInSilently()
                self.updateToken(token: token?.token)
                return try await parsed(t, uri, run: run, attempt: 2)
            } else {
                let decoder = JSONDecoder()
                let errors = (try? decoder.decode(Errors.self, from: response.data))?.errors ?? []
                throw AppError.responseFailure(ResponseDetails(url: url, code: response.statusCode, errors: errors))
            }
        }
    }
    
    func fullUrl(to: String) -> URL {
        URL(string: to, relativeTo: baseUrl)!
    }
    
    private func parseAs<T: Decodable>(_ t: T.Type, response: HttpResponse) throws -> T {
        do {
            let decoder = JSONDecoder()
//            if let str = String(data: response.data, encoding: .utf8) {
//                log.info("Response is: \(str)")
//            }
            return try decoder.decode(t, from: response.data)
        } catch let error as JsonError {
            self.log.error(error.describe)
            throw AppError.parseError(error)
        } catch DecodingError.dataCorrupted(let ctx) {
            self.log.error("Corrupted: \(ctx)")
            throw AppError.simple("Unknown parse error.")
        } catch DecodingError.typeMismatch(let t, let context) {
            self.log.error("Type mismatch: \(t) ctx \(context)")
            throw AppError.simple("Unknown parse error.")
        } catch DecodingError.keyNotFound(let key, let context) {
            self.log.error("Key not found: \(key) ctx \(context)")
            throw AppError.simple("Unknown parse error.")
        } catch let error {
            self.log.error(error.localizedDescription)
            throw AppError.simple("Unknown parse error.")
        }
    }
}
