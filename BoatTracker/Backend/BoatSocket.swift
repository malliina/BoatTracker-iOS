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

protocol VesselDelegate {
    func on(vessels: [Vessel])
}

class BoatSocket: SocketDelegate {
    private let log = LoggerFactory.shared.network(BoatSocket.self)
    
    let client: SocketClient
    
    // Delegate for the map view
    var delegate: BoatSocketDelegate? = nil
    // Delegate for the profile page with a summary view of the current track
    var statsDelegate: BoatSocketDelegate? = nil
    var vesselDelegate: VesselDelegate? = nil
    
    convenience init(token: AccessToken?, track: TrackName?) {
        var headers = [HttpClient.ACCEPT: BoatHttpClient.BoatVersion]
        if let token = token {
            headers.updateValue("bearer \(token.token)", forKey: HttpClient.AUTHORIZATION)
        }
        let trackQuery = track.map { "?track=\($0.name)" } ?? ""
        let url = URL(string: "/ws/updates\(trackQuery)", relativeTo: EnvConf.shared.baseUrl)!
        self.init(client: SocketClient(baseURL: url, headers: headers))
//        log.info("Opening socket with \(track?.name ?? "no track") and token \(token)")
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
    
    func onMessage(json: Data) {
        let decoder = JSONDecoder()
        do {
            let event = try decoder.decode(BoatEvent.self, from: json)
            switch event.event {
            case "ping":
                ()
            case "coords":
                let data = try decoder.decode(CoordsBody.self, from: json)
                if let delegate = delegate {
                    delegate.onCoords(event: data.body)
                } else {
                    log.warn("No delegate for coords. This is probably an error.")
                }
                if let delegate = statsDelegate {
                    delegate.onCoords(event: data.body)
                }
            case "vessels":
                let obj = try JsObject.parse(data: json)
                let vessels = try Vessel.list(json: obj.readObject("body"))
                vesselDelegate?.on(vessels: vessels)
            default:
                log.info("Unknown event: '\(event)'.")
            }
        } catch {
//            let obj = try JsObject.parse(data: json)
            if case JsonError.missing(let key) = error {
                log.error("Missing: \(key)")//" in \(obj.stringify())")
            } else if case JsonError.invalid(let msg, let value) = error{
                log.error("\(msg) with value \(value)")
            } else {
//                let str = String(data: json, encoding: .utf8)
                log.info("Unknown JSON.")
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

struct BoatEvent: Codable {
    let event: String
}
