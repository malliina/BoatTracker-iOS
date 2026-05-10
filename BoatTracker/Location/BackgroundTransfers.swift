class BackgroundTransfers: NSObject, URLSessionTaskDelegate,
  URLSessionDelegate
{
  static let shared = BackgroundTransfers(sessionId: "locations")
  
  let session: URLSession
  
  var transferCompletionHandlers: [String: () -> Void] = [:]
  
  init(sessionId: String) {
    let conf = URLSessionConfiguration.background(withIdentifier: sessionId)
    conf.isDiscretionary = false
    conf.sessionSendsLaunchEvents = true
    self.session = URLSession(configuration: conf)
  }
  
  func upload(data: Data, to: URL, headers: [String: String]) async throws {
    var req = URLRequest(url: to)
    req.addCsrf()
    req.httpMethod = HttpClient.post
    for (key, value) in headers {
      req.addValue(value, forHTTPHeaderField: key)
    }
    let (d, res) = try await session.upload(for: req, from: data)
  }
}
