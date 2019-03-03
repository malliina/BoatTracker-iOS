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
        var headers = [
            Headers.accept: BoatHttpClient.BoatVersion
//            Headers.acceptLanguage: language.rawValue
        ]
        if let token = token {
            headers.updateValue("bearer \(token.token)", forKey: Headers.authorization)
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
                let data = try decoder.decode(VesselsBody.self, from: json)
                vesselDelegate?.on(vessels: data.body.vessels)
            default:
                log.info("Unknown event: '\(event)'.")
            }
        } catch DecodingError.typeMismatch(let t, let ctx) {
            log.info("Type mismatch: '\(t) with context \(ctx)'. \(ctx.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let ctx) {
            log.info("Key not found: '\(key)' with context '\(ctx)'. \(ctx.debugDescription)")
        } catch DecodingError.valueNotFound(let t, let ctx) {
            log.info("Value not found in type: \(t) with context: '\(ctx)'. \(ctx.debugDescription)")
        } catch DecodingError.dataCorrupted(let ctx) {
            log.info("Data corrupted with context: 'ctx'. \(ctx.debugDescription)")
        } catch {
            if case JsonError.missing(let key) = error {
                log.error("Missing: \(key)")
            } else if case JsonError.invalid(let msg, let value) = error {
                log.error("\(msg) with value \(value)")
            } else {
                log.info("Unknown JSON.")
            }
        }
    }
    
    func send<T: Encodable>(t: T) -> SingleError? {
        guard let socket = client.socket else {
            return failWith("Unable to send payload, socket not available.")
        }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(t)
            guard let asString = String(data: data, encoding: .utf8) else {
                return failWith("Unable to send data, cannot stringify payload.")
            }
            socket.send(asString)
            return nil
        } catch {
            return failWith("Unable to send payload, encoding error.")
        }
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
