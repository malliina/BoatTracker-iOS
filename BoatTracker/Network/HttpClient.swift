import Foundation

struct Headers {
  static let accept = "Accept", acceptLanguage = "Accept-Language", authorization = "Authorization",
    contentType = "Content-Type"
}

class HttpClient {
  private let log = LoggerFactory.shared.network(HttpClient.self)
  static let json = "application/json", delete = "DELETE", get = "GET", patch = "PATCH",
    post = "POST", put = "PUT", basic = "Basic"

  static func basicAuthValue(_ username: String, password: String) -> String {
    let encodable = "\(username):\(password)"
    let encoded = encodeBase64(encodable)
    return "\(HttpClient.basic) \(encoded)"
  }

  static func authHeader(_ word: String, unencoded: String) -> String {
    let encoded = HttpClient.encodeBase64(unencoded)
    return "\(word) \(encoded)"
  }

  static func encodeBase64(_ unencoded: String) -> String {
    unencoded.data(using: String.Encoding.utf8)!.base64EncodedString(
      options: NSData.Base64EncodingOptions())
  }

  let session: URLSession

  init() {
    session = URLSession.shared
  }

  func executeHttp(_ req: URLRequest) async throws -> HttpResponse {
    let (data, response) = try await session.data(for: req)
    if let response = response as? HTTPURLResponse {
      return HttpResponse(http: response, data: data)
    } else {
      throw AppError.simple(
        "Non-HTTP response received from \(req.url?.absoluteString ?? "no url").")
    }
  }

  func buildRequestWithBody<T: Encodable>(
    url: URL, httpMethod: String, headers: [String: String], body: T?
  ) -> URLRequest {
    var req = buildRequest(url: url, httpMethod: httpMethod, headers: headers)
    if let body = body {
      let encoder = JSONEncoder()
      req.httpBody = try? encoder.encode(body)
    }
    return req
  }

  func buildRequest(url: URL, httpMethod: String, headers: [String: String]) -> URLRequest {
    var req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 3600)
    let useCsrfHeader = httpMethod != HttpClient.get
    if useCsrfHeader {
      req.addCsrf()
    }
    req.httpMethod = httpMethod
    for (key, value) in headers {
      req.addValue(value, forHTTPHeaderField: key)
    }
    return req
  }
}

extension URLRequest {
  mutating func addCsrf() {
    self.addValue("nocheck", forHTTPHeaderField: "Csrf-Token")
  }
}
