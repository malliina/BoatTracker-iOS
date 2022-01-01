//
//  Backend.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation
import RxCocoa

class Backend {
    static let shared = Backend(EnvConf.shared.baseUrl)
    let log = LoggerFactory.shared.system(Backend.self)
    
    let baseUrl: URL
    private var latestToken: UserToken? = nil
    
    var http: BoatHttpClient
    var socket: BoatSocket
    
    init(_ baseUrl: URL) {
        //Logging.URLRequests = { _ in false }
        self.baseUrl = baseUrl
        self.http = BoatHttpClient(bearerToken: nil, baseUrl: baseUrl, client: HttpClient())
        self.socket = BoatSocket(token: nil, track: nil)
        let _ = Auth.shared.tokens.subscribe(onNext: { token in
            self.updateToken(new: token)
        })
    }
    
    private func updateToken(new token: UserToken?) {
        latestToken = token
        http.updateToken(token: token?.token)
        socket.updateToken(token: token?.token)
        let keychain = Keychain.shared
        do {
            if let token = token?.token {
                try keychain.use(token: token)
            } else {
                try keychain.delete()
            }
        } catch {
            log.error("Keychain failure. \(error)")
        }
        
        //let d = socket.delegate
        //socket.close()
        //socket = BoatSocket(token: token?.token, track: nil)
    }
    
    func open(track: TrackName, delegate: BoatSocketDelegate) {
        socket.delegate = nil
        socket.close()
        socket = openStandalone(track: track, delegate: delegate)
    }
    
    func openStandalone(track: TrackName, delegate: BoatSocketDelegate) -> BoatSocket {
        let s = BoatSocket(token: latestToken?.token, track: track)
        s.delegate = delegate
        s.open()
        return s
    }
}
