//
//  EnvConf.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class EnvConf {
    static let shared = EnvConf()
    
    var server: String { return "www.boat-tracker.com" }
    private var devBaseUrl: URL { return URL(string: "http://10.0.0.21:9000")! }
    private var prodBaseUrl: URL { return URL(string: "https://\(server)")! }
    var baseUrl: URL { return devBaseUrl }
//    var baseUrl: URL { return prodBaseUrl }
}
