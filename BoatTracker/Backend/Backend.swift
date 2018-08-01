//
//  Backend.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class Backend {
    static let shared = Backend(EnvConf.BaseUrl)
    
    let baseUrl: URL
    private var latestToken: AccessToken? = nil
    //private var latestTrack: TrackName? = nil
    
    var http: BoatHttpClient
    var socket: BoatSocket
    
    init(_ baseUrl: URL) {
        self.baseUrl = baseUrl
        self.http = BoatHttpClient(bearerToken: nil, baseUrl: baseUrl, client: HttpClient())
        self.socket = BoatSocket(token: nil, track: nil)
    }
    
    func updateToken(new token: AccessToken?) {
        latestToken = token
        http.updateToken(token: token)
        socket.close()
        socket = BoatSocket(token: token, track: nil)
    }
    
    func open(track: TrackName, delegate: BoatSocketDelegate) {
        socket.delegate = nil
        socket.close()
        socket = BoatSocket(token: latestToken, track: track)
        socket.delegate = delegate
        socket.open()
    }
}
