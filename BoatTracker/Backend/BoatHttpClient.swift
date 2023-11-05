import Foundation
import MapboxMaps

class BoatHttpClient {
  private let log = LoggerFactory.shared.network(BoatHttpClient.self)

  static let BoatVersion = "application/vnd.boat.v2+json"

  let baseUrl: URL
  let client: HttpClient

  private var defaultHeaders: [String: String]
  private let postSpecificHeaders: [String: String]

  var postHeaders: [String: String] {
    defaultHeaders.merging(postSpecificHeaders) { (current, _) in current }
  }

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
        Headers.accept: BoatHttpClient.BoatVersion
      ]
    }
    self.postSpecificHeaders = [
      Headers.contentType: HttpClient.json
    ]
  }

  func updateToken(token: AccessToken?) {
    if let token = token {
      self.defaultHeaders.updateValue(
        BoatHttpClient.authValue(for: token), forKey: Headers.authorization)
    } else {
      self.defaultHeaders.removeValue(forKey: Headers.authorization)
    }
  }

  static func authValue(for token: AccessToken) -> String {
    "bearer \(token.token)"
  }

  func pingAuth() async throws -> BackendInfo {
    try await get("/pingAuth").to(BackendInfo.self)
  }

  // Call after UI sign in completes
  func register(code: RegisterCode) async throws -> TokenResponse {
    try await execute("/users/me", method: HttpClient.post, body: code)
      .to(TokenResponse.self)
  }

  // Call on app startup
  func obtainValidToken(token: AccessToken) async throws -> TokenResponse {
    updateToken(token: token)
    return try await executeNoBody("/users/me/tokens", method: HttpClient.post)
      .to(TokenResponse.self)
  }

  func profile() async throws -> UserProfile {
    try await get("/users/me").to(UserContainer.self).user
  }

  func tracks() async throws -> [TrackRef] {
    try await get("/tracks").to(TracksResponse.self).tracks
  }

  func stats() async throws -> StatsResponse {
    try await get("/stats?order=desc").to(StatsResponse.self)
  }

  func changeTrackTitle(name: TrackName, title: TrackTitle) async throws -> TrackResponse {
    try await execute(
      "/tracks/\(name)", method: HttpClient.put, body: ChangeTrackTitle(title: title)
    )
    .to(TrackResponse.self)
  }

  func conf() async throws -> ClientConf {
    try await get("/conf").to(ClientConf.self)
  }

  func enableNotifications(token: PushToken) async throws -> SimpleMessage {
    try await execute("/users/notifications", method: HttpClient.post, body: PushPayload(token))
      .to(SimpleMessage.self)
  }

  func disableNotifications(token: PushToken) async throws -> SimpleMessage {
    try await execute(
      "/users/notifications/disable", method: HttpClient.post, body: DisablePush(token: token)
    )
    .to(SimpleMessage.self)
  }

  func renameBoat(boat: Int, newName: BoatName) async throws -> Boat {
    try await execute(
      "/boats/\(boat)", method: HttpClient.patch, body: ChangeBoatName(boatName: newName)
    )
    .to(BoatResponse.self)
    .boat
  }

  func changeLanguage(to: Language) async throws -> SimpleMessage {
    try await execute("/users/me", method: HttpClient.put, body: ChangeLanguage(language: to))
      .to(SimpleMessage.self)
  }

  func deleteMe() async throws -> SimpleMessage {
    try await executeNoBody("/users/me/delete", method: HttpClient.post)
      .to(SimpleMessage.self)
  }

  func shortestRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws
    -> RouteResult
  {
    try await get("/routes/\(from.latitude)/\(from.longitude)/\(to.latitude)/\(to.longitude)")
      .to(RouteResult.self)
  }

  func get(_ path: String) async throws -> HttpResponse {
    try await executeNoBody(path, method: HttpClient.get)
  }

  func executeNoBody(_ path: String, method: String) async throws -> HttpResponse {
    let dummy: String? = nil
    return try await execute(path, method: method, body: dummy)
  }

  func execute<T: Encodable>(_ path: String, method: String, body: T? = nil) async throws
    -> HttpResponse
  {
    try await make(request: build(path: path, method: method, body: body))
  }

  func make(request: URLRequest, attempt: Int = 1) async throws -> HttpResponse {
    let response = try await client.executeHttp(request)
    if response.isStatusOK {
      return response
    } else {
      self.log.error(
        "Request to '\(request.url?.absoluteString ?? "no url")' failed with status '\(response.statusCode)'."
      )
      if attempt == 1 && response.isTokenExpired {
        let token = try await Auth.shared.signInSilently()
        self.updateToken(token: token?.token)
        var retry = request
        retry.setValue(
          token.map { t in BoatHttpClient.authValue(for: t.token) },
          forHTTPHeaderField: Headers.authorization)
        return try await make(request: retry, attempt: 2)
      } else {
        let decoder = JSONDecoder()
        let errors = (try? decoder.decode(Errors.self, from: response.data))?.errors ?? []
        if let url = request.url {
          throw AppError.responseFailure(
            ResponseDetails(url: url, code: response.statusCode, errors: errors))
        } else {
          let err = errors.headOption() ?? SingleError(message: "Failed to handle request.")
          throw AppError.simpleError(err)
        }
      }
    }
  }

  func build<T: Encodable>(path: String, method: String, body: T? = nil) -> URLRequest {
    let headers = method == HttpClient.get ? defaultHeaders : postHeaders
    return client.buildRequestWithBody(
      url: fullUrl(to: path), httpMethod: method, headers: headers, body: body)
  }

  func fullUrl(to: String) -> URL {
    URL(string: to, relativeTo: baseUrl)!
  }

  private func parseAs<T: Decodable>(_ t: T.Type, response: HttpResponse) throws -> T {
    do {
      let decoder = JSONDecoder()
      return try decoder.decode(t, from: response.data)
    } catch let error as JsonError {
      log.error(error.describe)
      throw AppError.parseError(error)
    } catch DecodingError.dataCorrupted(let ctx) {
      log.error("Corrupted: \(ctx)")
      throw AppError.simple("Unknown parse error.")
    } catch DecodingError.typeMismatch(let t, let context) {
      log.error("Type mismatch: \(t) ctx \(context)")
      throw AppError.simple("Unknown parse error.")
    } catch DecodingError.keyNotFound(let key, let context) {
      log.error("Key not found: \(key) ctx \(context)")
      throw AppError.simple("Unknown parse error.")
    } catch let error {
      log.error(error.localizedDescription)
      throw AppError.simple("Unknown parse error.")
    }
  }
}

extension HttpResponse {
  func to<T: Decodable>(_ t: T.Type) throws -> T {
    try HttpParser.shared.parseAs(t, response: self)
  }
}
