//
//  BoatSocket.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

protocol BoatSocketDelegate {
    func onCoords(event: CoordsData)
}

class BoatSocket: SocketDelegate {
    //static let SocketUrl = URL(string: "/ws/updates", relativeTo: EnvConf.BaseUrl)!
    
    private let log = LoggerFactory.shared.network(BoatSocket.self)
    
    let client: SocketClient
    
    var delegate: BoatSocketDelegate? = nil
    var statsDelegate: BoatSocketDelegate? = nil
    
    convenience init(token: AccessToken?, track: TrackName?) {
        var headers = [HttpClient.ACCEPT: BoatHttpClient.BoatVersion10]
        if let token = token {
            headers.updateValue("bearer \(token.token)", forKey: HttpClient.AUTHORIZATION)
        }
        let trackQuery = track.map { "?track=\($0.name)" } ?? ""
        let url = URL(string: "/ws/updates\(trackQuery)", relativeTo: EnvConf.shared.baseUrl)!
        self.init(client: SocketClient(baseURL: url, headers: headers))
//        log.info("Using \(token)")
    }
    
    init(client: SocketClient) {
        self.client = client
        client.delegate = self
    }
    
    func open() {
        client.openSilently()
    }
    
    func updateToken(token: AccessToken?) {
        client.updateAuthHeaderValue(newValue: token.map(BoatHttpClient.authValue))
    }
    
    func onMessage(json: JsObject) {
//        log.info("Got \(json.stringify())")
        do {
            let event = try json.readString("event")
            switch event {
            case "ping":
                ()
            case "coords":
                let data = try CoordsData.parse(json: json)
                if let delegate = delegate {
                    delegate.onCoords(event: data)
                } else {
                    log.warn("No delegate for coords. This is probably an error.")
                }
                if let delegate = statsDelegate {
                    delegate.onCoords(event: data)
                }
            default:
                log.info("Unknown event: '\(event)'.")
            }
        } catch {
            if case JsonError.missing(let key) = error {
                log.error("Missing: \(key)")
            } else if case JsonError.invalid(let msg, let value) = error{
                log.error("\(msg) with value \(value)")
            } else {
                log.info("Unknown JSON: '\(json.stringify())'.")
            }
        }
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
