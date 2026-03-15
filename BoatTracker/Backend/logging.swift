import Foundation

enum LogLevel: String, Codable {
  case debug = "debug", info = "info", warn = "warn", error = "error"
}

struct LogEvent: Codable {
  let timestamp: Date
  let message: String
  let loggerName: String
  let threadName: String
  let level: LogLevel
  let stackTrace: String?
}

struct LogEvents: Codable {
  let events: [LogEvent]
}

struct LogTokenRequest: Codable {
  let app: String
}

struct LogTokenResponse: Codable {
  let token: AccessToken
}

struct LogsSentResponse: Codable {
  let eventCount: Int
}

protocol TokenSource {
  func fetchToken() async throws -> AccessToken
}

class LogsTokenSource: TokenSource {
  let baseUrl: URL
  let client: HttpClient
  
  init(baseUrl: URL, client: HttpClient) {
    self.baseUrl = baseUrl
    self.client = client
  }
  
  func fetchToken() async throws -> AccessToken {
    return try await client.post(url: fullUrl(to: "/sources/token"), headers: LogsHttpClient.headers, body: LogTokenRequest(app: "boat-ios")).to(LogTokenResponse.self).token
  }
  
  func fullUrl(to: String) -> URL {
    URL(string: to, relativeTo: baseUrl)!
  }
}

class LogsHttpClient {
  private let log = LoggerFactory.shared.local(LogsHttpClient.self)
  
  static let headers = [
    Headers.accept: HttpClient.json,
    Headers.contentType: HttpClient.json
  ]
  
  let baseUrl: URL
  let client: HttpClient
  let tokens: TokenSource
  
  private var cachedToken: AccessToken? = nil
  
  func fetchToken() async throws -> AccessToken {
    if let cachedToken = cachedToken {
      return cachedToken
    }
    let refreshed = try await tokens.fetchToken()
    cachedToken = refreshed
    return refreshed
  }
  
  convenience init(baseUrl: URL, client: HttpClient) {
    self.init(baseUrl: baseUrl, client: client, tokens: LogsTokenSource(baseUrl: baseUrl, client: client))
  }
  
  init(baseUrl: URL, client: HttpClient, tokens: TokenSource) {
    self.baseUrl = baseUrl
    self.client = client
    self.tokens = tokens
  }
  
  func listen() async {
    for await events in Logger.logs {
      do {
        let res = try await send(logs: events)
        log.info("Sent \(res.eventCount) events to \(baseUrl).")
      } catch {
        log.error("Failed to send logs to \(baseUrl). \(error)")
      }
    }
  }
  
  func send(logs: [LogEvent], attempt: Int = 1) async throws -> LogsSentResponse {
    let token = try await fetchToken()
    let allHeaders = LogsHttpClient.headers.merging([Headers.authorization: "Bearer \(token.token)"]) { (_, newVal) in newVal }
    let url = fullUrl(to: "/sources/logs")
    let response = try await client.post(url: url, headers: allHeaders, body: LogEvents(events: logs))
    if response.isStatusOK {
      return try response.to(LogsSentResponse.self)
    } else {
      if attempt == 1 && response.isTokenExpired {
        let newToken = try await tokens.fetchToken()
        cachedToken = newToken
        return try await send(logs: logs, attempt: 2)
      } else {
        let error = SingleError(message: "Failed to handle \(response.statusCode) response from \(url) after \(attempt) attempts.")
        throw AppError.simpleError(error)
      }
    }
  }
  
  func fullUrl(to: String) -> URL {
    URL(string: to, relativeTo: baseUrl)!
  }
}
