//
//  WebSocket.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 13.2.2022.
//  Copyright © 2022 Michael Skogberg. All rights reserved.
//

import Foundation

protocol WebSocketMessageDelegate {
    func on(message: String)
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
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue())
        task = session?.webSocketTask(with: request)
    }
    
    func connect() {
        log.info("Connecting to \(urlString)...")
        task?.resume()
    }
    
    func send(_ msg: String) -> Bool {
        if let task = task {
            task.send(.string(msg), completionHandler: { error in
                if let error = error {
                    self.log.warn("Failed to send '\(msg)' over socket \(self.baseURL). \(error)")
                }
            })
            return true
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
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        log.info("Connected to \(urlString).")
        isConnected = true
        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        log.info("Disconnected from \(urlString).")
        isConnected = false
    }
    
    private func receive() {
      task?.receive { result in
        switch result {
        case .success(let message):
          switch message {
          case .data(let data):
            self.log.warn("Data received \(data)")
          case .string(let text):
//            self.log.debug("Text received \(text)")
            self.delegate?.on(message: text)
            self.receive()
          default:
              self.log.info("Received something.")
          }
        case .failure(let error):
            self.log.error("Error when receiving \(error)")
        }
      }
    }
    
    func disconnect() {
      let reason = "Closing connection".data(using: .utf8)
      task?.cancel(with: .goingAway, reason: reason)
    }
}