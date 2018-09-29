//
//  SocketClient.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import SocketRocket

protocol SocketDelegate {
    func onMessage(json: JsObject)
}

// Web socket that supports reconnects
class SocketClient: NSObject, SRWebSocketDelegate {
    private let log = LoggerFactory.shared.network(SocketClient.self)
    var socket: SRWebSocket? = nil
    let baseURL: URL
    fileprivate var request: URLRequest
    var isConnected = false
    
    var onOpenCallback: (() -> Void)? = nil
    var onOpenErrorCallback: ((Error) -> Void)? = nil
    
    var delegate: SocketDelegate? = nil
    
    init(baseURL: URL, headers: [String: String]) {
        self.baseURL = baseURL
        self.request = URLRequest(url: self.baseURL)
        for (key, value) in headers {
            self.request.addValue(value, forHTTPHeaderField: key)
        }
        super.init()
    }
    
    func updateAuthHeaderValue(newValue: String?) {
        request.setValue(newValue, forHTTPHeaderField: HttpClient.AUTHORIZATION)
    }
    
    func openSilently() {
        open({
            
        }) { (err) in
            
        }
    }
    
    /// Calling this method on an already open socket will first close the socket then reconnect
    func open(_ onOpen: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        close()
        let webSocket = SRWebSocket(urlRequest: request)
        webSocket?.delegate = self
        self.socket = webSocket
        self.onOpenCallback = onOpen
        self.onOpenErrorCallback = onError
        webSocket?.open()
        // log.info("Connecting to \(baseURL)...")
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        do {
            let obj = try JsObject.parse(any: message)
            delegate?.onMessage(json: obj)
        } catch {
            if let message = message as? String {
                log.info("Got message \(message)")
            } else {
                log.info("Got data \(message ?? "")")
            }
        }
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        if webSocket != self.socket {
            return
        }
        isConnected = true
        log.info("Socket opened to \(baseURL.absoluteString)")
        if let onOpen = onOpenCallback {
            onOpen()
            onOpenCallback = nil
            onOpenErrorCallback = nil
        }
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        isConnected = false
        log.info("Error for connection to \(baseURL.absoluteString)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        isConnected = false
        log.info("Connection failed to \(baseURL.absoluteString). \(error?.describe ?? "")")
        if let onError = onOpenErrorCallback {
            onError(error)
            onOpenCallback = nil
            onOpenErrorCallback = nil
        }
    }
    
    func close() {
        // disposes of any previous socket
        if let socket = socket {
            socket.delegate = nil
            socket.close()
            self.socket = nil
        }
        isConnected = false
    }
}

class LoggingSRSocketDelegate: NSObject, SRWebSocketDelegate {
    let log = LoggerFactory.shared.network(LoggingSRSocketDelegate.self)
    let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        info("Closed socket to \(baseURL), code: \(code)")
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        info("Failed socket to \(baseURL)")
    }
    
    public func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        let msg = String(describing: message)
        info("Got message from \(baseURL): \(msg)")
    }
    
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        info("Opened socket to \(baseURL)")
    }
    
    func info(_ s: String) {
        log.info(s)
    }
}
