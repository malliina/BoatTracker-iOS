//
//  EnvConf.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 10/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import Foundation

class EnvConf {
    static let Server = "www.boat-tracker.com"
    static let DevBaseUrl = URL(string: "http://localhost:9000")!
    static let ProdBaseUrl = URL(string: "https://\(EnvConf.Server)")!
//     static let BaseUrl = DevBaseUrl
    static let BaseUrl = ProdBaseUrl
}
