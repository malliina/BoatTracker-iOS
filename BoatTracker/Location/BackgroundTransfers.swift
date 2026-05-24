// TODO scope to user
class BackgroundTransfers: NSObject, URLSessionTaskDelegate,
  URLSessionDelegate
{
  static let shared = BackgroundTransfers()
  
  let log = LoggerFactory.shared.system(BackgroundTransfers.self)
  
  var transferCompletionHandlers: [String: () -> Void] = [:]
  
  private lazy var session: URLSession = setupSession()
  
  let staging: Files
  let uploading: Files
  
  override init() {
    staging = Files.documents.folder(name: "locations")
    uploading = Files.documents.folder(name: "uploading")
  }
  
  private func setupSession() -> URLSession {
    let conf = URLSessionConfiguration.background(withIdentifier: "locations")
    conf.isDiscretionary = false
    conf.sessionSendsLaunchEvents = true
    return URLSession(configuration: conf, delegate: self, delegateQueue: nil)
  }
  
  func uploadAll(to: URL, headers: [String: String]) async throws {
    for url in staging.listFilesOldestFirst() {
      try await upload(file: url, to: to, headers: headers)
    }
  }
  
  func upload(file: URL, to: URL, headers: [String: String]) async throws {
    let from = uploading.baseUrl.appending(path: file.lastPathComponent, directoryHint: .notDirectory)
    try uploading.fileManager.moveItem(at: file, to: from)
    log.info("Moved \(file) to \(from). Submitting upload...")
    var req = URLRequest(url: to)
    req.addCsrf()
    req.httpMethod = HttpClient.post
    for (key, value) in headers {
      req.addValue(value, forHTTPHeaderField: key)
    }
    let task = session.uploadTask(with: req, fromFile: from)
    save(task: task.taskIdentifier, url: from)
    task.resume()
  }
  
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
    if let url = findAndRemove(task: task.taskIdentifier) {
      if let error = error {
        log.error("Upload of \(url) failed. \(error)")
        moveToStaging(url: url)
      } else if let response = task.response as? HTTPURLResponse {
        let isSuccess = response.statusCode >= 200 && response.statusCode < 400
        if isSuccess {
          log.info("Upload of \(url) completed successfully. Removing file...")
          do {
            try uploading.fileManager.removeItem(at: url)
            log.info("Removed \(url).")
          } catch {
            log.error("Failed to delete file at \(url). \(error)")
          }
        } else {
          log.error("Upload of \(url) returned \(response.statusCode).")
          moveToStaging(url: url)
        }
      } else {
        log.error("Upload of \(url) returned non-HTTP response.")
        moveToStaging(url: url)
      }
    } else {
      log.warn("Task \(task.taskIdentifier) completed, file unknown.")
    }
  }
  
  private func moveToStaging(url: URL) {
    // Try again, do not delete file
    let stagingFile = staging.baseUrl.appending(path: url.lastPathComponent, directoryHint: .notDirectory)
    do {
      try uploading.fileManager.moveItem(at: url, to: stagingFile)
    } catch {
      log.error("Failed to move \(url) to \(stagingFile).")
    }
  }
  
  private func save(task: Int, url: URL) {
    UserDefaults.standard.set(url.absoluteString, forKey: key(task: task))
  }
  
  private func findAndRemove(task: Int) -> URL? {
    let taskKey = key(task: task)
    if let str = UserDefaults.standard.string(forKey: taskKey) {
      UserDefaults.standard.removeObject(forKey: taskKey)
      return URL(string: str)
    }
    return nil
  }
  
  private func key(task: Int) -> String {
    "upload-\(task)"
  }
  
  // URLSessionDelegate
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    if let sid = session.configuration.identifier,
        let handler = self.transferCompletionHandlers.removeValue(forKey: sid) {
      DispatchQueue.main.async {
        handler()
      }
    }
  }
}
