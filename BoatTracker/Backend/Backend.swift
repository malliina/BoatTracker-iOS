//
//  Backend.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class Backend {
    let shared = Backend(EnvConf.BaseUrl)
    let baseUrl: URL
//    let http: BoatHttpClient
    
    init(_ baseUrl: URL) {
        self.baseUrl = baseUrl
//        self.http = BoatHttpClient(bearerToken: <#T##AccessToken#>)
    }
}
