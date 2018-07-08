//
//  BoatSocket.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class BoatSocket: SocketDelegate {
    static let ProdBaseUrl = URL(string: "https://boat.malliina.com")!
    static let ProdUrl = URL(string: "/ws/updates", relativeTo: ProdBaseUrl)!
    
    private let log = LoggerFactory.shared.network(BoatSocket.self)
    
    let client: SocketClient
    
    convenience init() {
        self.init(client: SocketClient(baseURL: BoatSocket.ProdUrl, headers: [:]))
    }
    
    init(client: SocketClient) {
        self.client = client
        client.delegate = self
    }
    
    func open() {
        client.openSilently()
    }
    
    func onMessage(json: JsObject) {
        
    }
    
    func send(_ dict: [String: AnyObject]) -> SingleError? {
        guard let socket = client.socket else { return failWith("Unable to send payload, socket not available.") }
        guard let payload = Json.stringifyObject(dict, prettyPrinted: false) else { return failWith("Unable to send payload, encountered non-JSON payload: \(dict)") }
        socket.send(payload)
        return nil
    }
    
    func failWith(_ message: String) -> SingleError {
        log.error(message)
        return SingleError(message: message)
    }
    
    func close() {
        client.close()
    }
}
