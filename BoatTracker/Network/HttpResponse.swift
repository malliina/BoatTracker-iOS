import Foundation

class HttpResponse {
  static let log = LoggerFactory.shared.network(HttpResponse.self)

  let http: HTTPURLResponse
  let data: Data

  var statusCode: Int { http.statusCode }
  var isStatusOK: Bool { statusCode >= 200 && statusCode < 300 }

  var errors: [SingleError] {
    let decoder = JSONDecoder()
    do {
      return try decoder.decode(Errors.self, from: data).errors
    } catch {
      HttpResponse.log.error(
        "HTTP response failed, and failed to parse error model. \(error.describe)")
      return []
    }
  }
  var isTokenExpired: Bool {
    return errors.contains { $0.key == "token_expired" }
  }

  init(http: HTTPURLResponse, data: Data) {
    self.http = http
    self.data = data
  }
}

class ResponseDetails {
  let url: URL
  let code: Int
  let errors: [SingleError]

  var message: String? { errors.first?.message }

  init(url: URL, code: Int, errors: [SingleError]) {
    self.url = url
    self.code = code
    self.errors = errors
  }
}

class HttpParser {
  static let shared = HttpParser()

  let log = LoggerFactory.shared.network(HttpParser.self)

  func parseAs<T: Decodable>(_ t: T.Type, response: HttpResponse) throws -> T {
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
