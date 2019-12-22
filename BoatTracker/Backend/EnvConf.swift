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

    var server: String {
        "www.boat-tracker.com"
    }
    private var devBaseUrl: URL {
        URL(string: "http://localhost:9000")!
    }
    private var prodBaseUrl: URL {
        URL(string: "https://\(server)")!
    }
//    var baseUrl: URL { return devBaseUrl }
    var baseUrl: URL {
        prodBaseUrl
    }
}
