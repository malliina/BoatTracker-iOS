import Foundation

protocol WebSocketMessageDelegate {
  func on(message: String) async
  func on(isConnected: Bool) async
}

class WebSocket: NSObject, URLSessionWebSocketDelegate {
  private let log = LoggerFactory.shared.network(WebSocket.self)
  let sessionConfiguration: URLSessionConfiguration
  let baseURL: URL
  var urlString: String { baseURL.absoluteString }
  private var session: URLSession? = nil
  fileprivate var request: URLRequest
  private var task: URLSessionWebSocketTask?
  private var isConnected = false
  var delegate: WebSocketMessageDelegate? = nil

  init(baseURL: URL, headers: [String: String]) {
    self.baseURL = baseURL
    self.request = URLRequest(url: self.baseURL)
    for (key, value) in headers {
      self.request.addValue(value, forHTTPHeaderField: key)
    }
    sessionConfiguration = URLSessionConfiguration.default
    super.init()
    sessionConfiguration.httpAdditionalHeaders = headers
    prepTask()
  }

  private func prepTask() {
    session = URLSession(
      configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue())
    task = session?.webSocketTask(with: request)
  }

  func connect() {
    log.info("Connecting to \(urlString)...")
    task?.resume()
  }

  func send(_ msg: String) async -> Bool {
    if let task = task {
      do {
        try await task.send(.string(msg))
        return true
      } catch {
        self.log.warn("Failed to send '\(msg)' over socket \(self.baseURL). \(error)")
        return false
      }
    } else {
      return false
    }
  }

  /** Fucking Christ Swift sucks. "Authorization" is a "reserved header" where iOS chooses not to send its value even when set, it seems. So we set it in two ways anyway and hope that either works: both to the request and the session configuration.
     */
  func updateAuthHeader(newValue: String?) {
    request.setValue(newValue, forHTTPHeaderField: Headers.authorization)
    if let value = newValue {
      sessionConfiguration.httpAdditionalHeaders = [Headers.authorization: value]
    } else {
      sessionConfiguration.httpAdditionalHeaders = [:]
    }
    prepTask()
  }

  func urlSession(
    _ session: URLSession, webSocketTask: URLSessionWebSocketTask,
    didOpenWithProtocol protocol: String?
  ) {
    log.info("Connected to \(urlString).")
    isConnected = true
    Task {
      if let delegate = delegate {
        await delegate.on(isConnected: true)
      }
      await receive()
    }
  }

  func urlSession(
    _ session: URLSession, webSocketTask: URLSessionWebSocketTask,
    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?
  ) {
    log.info("Disconnected from \(urlString).")
    isConnected = false
    if let delegate = delegate {
      Task {
        await delegate.on(isConnected: false)
      }
    }
  }

  private func receive() async {
    do {
      guard let result = try await task?.receive() else { return }
      switch result {
      case .data(let data):
        self.log.warn("Data received \(data)")
      case .string(let text):
        await self.delegate?.on(message: text)
        await self.receive()
      default:
        self.log.info("Received something.")
      }
    } catch {
      self.log.error("Error when receiving \(error)")
    }
  }

  func disconnect() {
    let reason = "Closing connection".data(using: .utf8)
    task?.cancel(with: .goingAway, reason: reason)
  }
}
