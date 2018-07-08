//
//  ViewController.swift
//  BoatTracker
//
//  Created by Michael Skogberg on 08/07/2018.
//  Copyright © 2018 Michael Skogberg. All rights reserved.
//

import UIKit
import SnapKit
import Mapbox

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "mapbox://styles/malliina/cjgny1fjc008p2so90sbz8nbv")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 60.14, longitude: 24.9), zoomLevel: 10, animated: false)
        view.addSubview(mapView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
